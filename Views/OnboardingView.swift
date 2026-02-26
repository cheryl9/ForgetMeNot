import SwiftUI
import PhotosUI

// MARK: - Person model for onboarding
struct PersonProfile: Identifiable, Codable {
    var id = UUID()
    var name: String = ""
    var relationship: String = ""
    var location: String = ""
    var funFact: String = ""
    // FILE-BASED: store filename only, not raw Data
    var imageFilename: String? = nil

    // Convenience accessor — loads from disk on demand
    var image: UIImage? { ImageFileStorage.load(imageFilename) }
}

// MARK: - Memory Entry for onboarding
struct OnboardingMemory: Identifiable, Codable {
    var id = UUID()
    var personName: String = ""
    var location: String = ""
    var activity: String = ""
    var dateTaken: String = ""
    // FILE-BASED: store filename only, not raw Data
    var imageFilename: String? = nil

    var image: UIImage? { ImageFileStorage.load(imageFilename) }
}

// MARK: - Onboarding Store (per-user)
class OnboardingStore: ObservableObject {
    @Published var hasCompletedOnboarding: Bool = false
    @Published var patientName: String = ""
    @Published var people: [PersonProfile] = []
    @Published var onboardingMemories: [OnboardingMemory] = []
    private var userKey: String = "guest"

    init() {}

    func load(for username: String) {
        userKey = username.lowercased().trimmingCharacters(in: .whitespaces)
        hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "onboarding_completed_\(userKey)")
        patientName = UserDefaults.standard.string(forKey: "onboarding_name_\(userKey)") ?? ""
        if let data = UserDefaults.standard.data(forKey: "onboarding_people_\(userKey)"),
           let decoded = try? JSONDecoder().decode([PersonProfile].self, from: data) {
            people = decoded
        } else { people = [] }
        if let data = UserDefaults.standard.data(forKey: "onboarding_memories_\(userKey)"),
           let decoded = try? JSONDecoder().decode([OnboardingMemory].self, from: data) {
            onboardingMemories = decoded
        } else { onboardingMemories = [] }
    }

    func completeOnboarding(patientName: String, people: [PersonProfile], memories: [OnboardingMemory]) {
        self.patientName = patientName
        self.people = people
        self.onboardingMemories = memories
        self.hasCompletedOnboarding = true
        persist()
    }

    func resetOnboarding() {
        // Clean up image files on disk before wiping
        people.forEach { ImageFileStorage.delete($0.imageFilename) }
        onboardingMemories.forEach { ImageFileStorage.delete($0.imageFilename) }
        hasCompletedOnboarding = false
        patientName = ""
        people = []
        onboardingMemories = []
        persist()
    }

    private func persist() {
        UserDefaults.standard.set(hasCompletedOnboarding, forKey: "onboarding_completed_\(userKey)")
        UserDefaults.standard.set(patientName, forKey: "onboarding_name_\(userKey)")
        // Only tiny filenames go into UserDefaults now — no image blobs
        if let e = try? JSONEncoder().encode(people) { UserDefaults.standard.set(e, forKey: "onboarding_people_\(userKey)") }
        if let e = try? JSONEncoder().encode(onboardingMemories) { UserDefaults.standard.set(e, forKey: "onboarding_memories_\(userKey)") }
    }
}

// MARK: - Onboarding Container
struct OnboardingView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var onboardingStore: OnboardingStore
    @State private var currentStep = 0
    @State private var patientName = ""
    @State private var person1 = PersonProfile()
    @State private var person2 = PersonProfile()
    @State private var memory1 = OnboardingMemory()
    @State private var memory2 = OnboardingMemory()

    let totalSteps = 6

    var body: some View {
        ZStack {
            Image("garden_background")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
            Color.white.opacity(0.45).ignoresSafeArea()

            VStack {
                HStack(spacing: 8) {
                    ForEach(0..<totalSteps, id: \.self) { i in
                        Circle()
                            .fill(i == currentStep ? Color(hex: "7ba7bc") : Color(hex: "cccccc"))
                            .frame(width: i == currentStep ? 10 : 7, height: i == currentStep ? 10 : 7)
                            .animation(.spring(), value: currentStep)
                    }
                }
                .padding(.top, 60)

                Spacer()

                Group {
                    switch currentStep {
                    case 0:
                        WelcomeStepView(patientName: $patientName, onNext: { currentStep = 1 })
                    case 1:
                        PersonStepView(person: $person1, index: 0, onNext: { currentStep = 2 })
                    case 2:
                        PersonStepView(person: $person2, index: 1, onNext: { currentStep = 3 })
                    case 3:
                        MemoryStepView(memory: $memory1, index: 0, onNext: { currentStep = 4 })
                    case 4:
                        MemoryStepView(memory: $memory2, index: 1, onNext: { currentStep = 5 })
                    default:
                        OnboardingDoneView(onFinish: {
                            onboardingStore.completeOnboarding(
                                patientName: patientName,
                                people: [person1, person2],
                                memories: [memory1, memory2]
                            )
                            authManager.requiresOnboarding = false
                        })
                    }
                }

                Spacer()
            }
        }
    }
}

// MARK: - Step 1: Welcome
struct WelcomeStepView: View {
    @Binding var patientName: String
    let onNext: () -> Void
    @FocusState private var focused: Bool

    var body: some View {
        VStack(spacing: 28) {
            VStack(spacing: 10) {
                Text("Welcome")
                    .font(.custom("Snell Roundhand", size: 42))
                    .foregroundColor(Color(hex: "7ba7bc"))
                Text("Let's set up your loved one's memory garden")
                    .font(.custom("Georgia", size: 16))
                    .foregroundColor(Color(hex: "888888"))
                    .multilineTextAlignment(.center)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("What is their name?")
                    .font(.custom("Georgia", size: 15))
                    .foregroundColor(Color(hex: "666666"))
                    .padding(.horizontal, 4)
                TextField("e.g. Grandma Rose", text: $patientName)
                    .font(.custom("Georgia", size: 17))
                    .foregroundColor(Color(hex: "333333"))
                    .padding(16)
                    .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.9)))
                    .focused($focused)
            }
            .padding(.horizontal, 32)

            OnboardingNextButton(label: "Let's Begin →", enabled: !patientName.trimmingCharacters(in: .whitespaces).isEmpty) {
                onNext()
            }
        }
        .padding(32)
        .frame(maxWidth: min(420, UIScreen.main.bounds.width - 40))
        .background(
            RoundedRectangle(cornerRadius: 36)
                .fill(Color.white.opacity(0.55))
                .background(RoundedRectangle(cornerRadius: 36).fill(.ultraThinMaterial))
                .overlay(RoundedRectangle(cornerRadius: 36).stroke(Color.white.opacity(0.7), lineWidth: 1.5))
                .shadow(color: .black.opacity(0.10), radius: 30, x: 0, y: 10)
        )
        .onAppear { focused = true }
    }
}

// MARK: - Step 2 & 3: Person Entry
struct PersonStepView: View {
    @Binding var person: PersonProfile
    let index: Int
    let onNext: () -> Void

    @State private var showPhotoPicker = false
    @State private var selectedImage: UIImage?

    var canProceed: Bool {
        !person.name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !person.relationship.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(spacing: 6) {
                    Text("Person \(index + 1) of 2")
                        .font(.custom("Georgia", size: 13))
                        .foregroundColor(Color(hex: "aaaaaa"))
                    Text("Tell us about them")
                        .font(.custom("Snell Roundhand", size: 34))
                        .foregroundColor(Color(hex: "7ba7bc"))
                }

                Button { showPhotoPicker = true } label: {
                    ZStack {
                        if let img = selectedImage {
                            Image(uiImage: img)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 110, height: 110)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color(hex: "7ba7bc").opacity(0.4), lineWidth: 3))
                        } else {
                            Circle()
                                .fill(Color(hex: "f0f5f8"))
                                .frame(width: 110, height: 110)
                                .overlay(
                                    VStack(spacing: 6) {
                                        Image(systemName: "camera.fill")
                                            .font(.system(size: 24))
                                            .foregroundColor(Color(hex: "aaaaaa"))
                                        Text("Add Photo")
                                            .font(.custom("Georgia", size: 12))
                                            .foregroundColor(Color(hex: "aaaaaa"))
                                    }
                                )
                                .overlay(Circle().stroke(Color(hex: "dddddd"), lineWidth: 1.5))
                        }
                    }
                }

                VStack(spacing: 12) {
                    OnboardingField(icon: "person.fill", placeholder: "Their name (required)", text: $person.name, color: Color(hex: "7ba7bc"))
                    OnboardingField(icon: "heart.fill", placeholder: "Relationship, e.g. Daughter (required)", text: $person.relationship, color: Color(hex: "f07080"))
                    OnboardingField(icon: "mappin.circle.fill", placeholder: "Where do they live? e.g. Queenstown", text: $person.location, color: Color(hex: "a8c5a0"))
                    OnboardingField(icon: "star.fill", placeholder: "A fun fact, e.g. Loves gardening", text: $person.funFact, color: Color(hex: "f0a030"))
                }

                OnboardingNextButton(
                    label: index == 0 ? "Next Person →" : "Next: Memories →",
                    enabled: canProceed,
                    action: onNext
                )
            }
            .padding(28)
        }
        .frame(maxWidth: min(420, UIScreen.main.bounds.width - 40))
        .background(
            RoundedRectangle(cornerRadius: 36)
                .fill(Color.white.opacity(0.55))
                .background(RoundedRectangle(cornerRadius: 36).fill(.ultraThinMaterial))
                .overlay(RoundedRectangle(cornerRadius: 36).stroke(Color.white.opacity(0.7), lineWidth: 1.5))
                .shadow(color: .black.opacity(0.10), radius: 30, x: 0, y: 10)
        )
        .sheet(isPresented: $showPhotoPicker) {
            ImagePicker(image: $selectedImage)
        }
        .onChange(of: selectedImage) {
            guard let img = selectedImage else { return }
            // Write to file, replacing previous file for this person slot
            person.imageFilename = ImageFileStorage.replace(old: person.imageFilename, with: img)
        }
        .onAppear {
            // Fast disk read instead of decoding from UserDefaults
            selectedImage = ImageFileStorage.load(person.imageFilename)
        }
    }
}

// MARK: - Step 4 & 5: Memory Entry
struct MemoryStepView: View {
    @Binding var memory: OnboardingMemory
    let index: Int
    let onNext: () -> Void

    @State private var showPhotoPicker = false
    @State private var selectedImage: UIImage?

    var canProceed: Bool {
        !memory.personName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(spacing: 6) {
                    Text("Memory \(index + 1) of 2")
                        .font(.custom("Georgia", size: 13))
                        .foregroundColor(Color(hex: "aaaaaa"))
                    Text("Add a memory")
                        .font(.custom("Snell Roundhand", size: 34))
                        .foregroundColor(Color(hex: "7ba7bc"))
                }

                Button { showPhotoPicker = true } label: {
                    ZStack {
                        if let img = selectedImage {
                            Image(uiImage: img)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 110, height: 110)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(hex: "7ba7bc").opacity(0.4), lineWidth: 3))
                        } else {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(hex: "f0f5f8"))
                                .frame(width: 110, height: 110)
                                .overlay(
                                    VStack(spacing: 6) {
                                        Image(systemName: "photo.badge.plus")
                                            .font(.system(size: 24))
                                            .foregroundColor(Color(hex: "aaaaaa"))
                                        Text("Add Photo")
                                            .font(.custom("Georgia", size: 12))
                                            .foregroundColor(Color(hex: "aaaaaa"))
                                    }
                                )
                                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(hex: "dddddd"), lineWidth: 1.5))
                        }
                    }
                }

                VStack(spacing: 12) {
                    OnboardingField(icon: "person.fill", placeholder: "Who is in this memory? (required)", text: $memory.personName, color: Color(hex: "7ba7bc"))
                    OnboardingField(icon: "mappin.circle.fill", placeholder: "Where was this?", text: $memory.location, color: Color(hex: "a8c5a0"))
                    OnboardingField(icon: "figure.walk", placeholder: "What were they doing?", text: $memory.activity, color: Color(hex: "f0a030"))
                    OnboardingField(icon: "calendar", placeholder: "When? e.g. Christmas 2022", text: $memory.dateTaken, color: Color(hex: "c97b84"))
                }

                OnboardingNextButton(
                    label: index == 0 ? "Next Memory →" : "Almost done →",
                    enabled: canProceed,
                    action: onNext
                )
            }
            .padding(28)
        }
        .frame(maxWidth: min(420, UIScreen.main.bounds.width - 40))
        .background(
            RoundedRectangle(cornerRadius: 36)
                .fill(Color.white.opacity(0.55))
                .background(RoundedRectangle(cornerRadius: 36).fill(.ultraThinMaterial))
                .overlay(RoundedRectangle(cornerRadius: 36).stroke(Color.white.opacity(0.7), lineWidth: 1.5))
                .shadow(color: .black.opacity(0.10), radius: 30, x: 0, y: 10)
        )
        .sheet(isPresented: $showPhotoPicker) {
            ImagePicker(image: $selectedImage)
        }
        .onChange(of: selectedImage) {
            guard let img = selectedImage else { return }
            memory.imageFilename = ImageFileStorage.replace(old: memory.imageFilename, with: img)
        }
        .onAppear {
            selectedImage = ImageFileStorage.load(memory.imageFilename)
        }
    }
}

// MARK: - Done Step
struct OnboardingDoneView: View {
    let onFinish: () -> Void

    var body: some View {
        VStack(spacing: 28) {
            Text("🌷").font(.system(size: 64))
            VStack(spacing: 10) {
                Text("All set!")
                    .font(.custom("Snell Roundhand", size: 42))
                    .foregroundColor(Color(hex: "7ba7bc"))
                Text("The memory garden is ready.\nQuiz questions will be created automatically from the people you added.")
                    .font(.custom("Georgia", size: 15))
                    .foregroundColor(Color(hex: "888888"))
                    .multilineTextAlignment(.center)
            }
            OnboardingNextButton(label: "Enter the Garden 🌸", enabled: true, action: onFinish)
        }
        .padding(36)
        .frame(maxWidth: min(420, UIScreen.main.bounds.width - 40))
        .background(
            RoundedRectangle(cornerRadius: 36)
                .fill(Color.white.opacity(0.55))
                .background(RoundedRectangle(cornerRadius: 36).fill(.ultraThinMaterial))
                .overlay(RoundedRectangle(cornerRadius: 36).stroke(Color.white.opacity(0.7), lineWidth: 1.5))
                .shadow(color: .black.opacity(0.10), radius: 30, x: 0, y: 10)
        )
    }
}

// MARK: - Reusable field
struct OnboardingField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 20)
            TextField(placeholder, text: $text)
                .font(.custom("Georgia", size: 15))
                .foregroundColor(Color(hex: "333333"))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 13)
        .background(RoundedRectangle(cornerRadius: 13).fill(Color.white.opacity(0.9)))
    }
}

// MARK: - Reusable next button
struct OnboardingNextButton: View {
    let label: String
    let enabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.custom("Georgia", size: 17))
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(enabled
                              ? LinearGradient(colors: [Color(hex: "7ba7bc"), Color(hex: "a8c5a0")], startPoint: .leading, endPoint: .trailing)
                              : LinearGradient(colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.25)], startPoint: .leading, endPoint: .trailing))
                )
        }
        .disabled(!enabled)
    }
}