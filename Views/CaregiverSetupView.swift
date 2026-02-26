import SwiftUI
import PhotosUI
import AVFoundation

// MARK: - Caregiver Setup View
struct CaregiverSetupView: View {
    @EnvironmentObject var memoryStore: MemoryStore
    @Environment(\.dismiss) var dismiss
    @State private var showAddMemory = false

    var body: some View {
        ZStack {
            Image("garden_background")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
            Color.white.opacity(0.5).ignoresSafeArea()

            VStack(spacing: 0) {
                if memoryStore.memories.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 48))
                            .foregroundColor(Color(hex: "aaaaaa"))
                        Text("No memories yet")
                            .font(.custom("Georgia", size: 18))
                            .foregroundColor(Color(hex: "888888"))
                        Text("Tap + to add a photo or voice memory")
                            .font(.custom("Georgia", size: 14))
                            .foregroundColor(Color(hex: "aaaaaa"))
                    }
                    .padding(32)
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Color.white.opacity(0.75))
                            .shadow(color: .black.opacity(0.08), radius: 16, x: 0, y: 6)
                    )
                    .padding(.horizontal, 40)
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 14) {
                            ForEach(memoryStore.memories) { memory in
                                MemoryCard(memory: memory)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                    }
                }
            }

            // Floating buttons
            VStack {
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Color(hex: "7ba7bc"))
                            .padding(10)
                            .background(Circle().fill(Color.white.opacity(0.9)))
                            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                    }
                    Spacer()
                    Button(action: { showAddMemory = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(Color(hex: "7ba7bc"))
                            .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 60)
                Spacer()
            }
        }
        .sheet(isPresented: $showAddMemory) {
            AddMemoryView()
                .environmentObject(memoryStore)
        }
    }
}

// MARK: - Memory Card (list row)
struct MemoryCard: View {
    @EnvironmentObject var memoryStore: MemoryStore
    let memory: Memory

    // Loaded asynchronously so the list stays smooth
    @State private var loadedImage: UIImage?

    var body: some View {
        HStack(spacing: 14) {
            if memory.type == .photo {
                if let img = loadedImage {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 64, height: 64)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(hex: "eeeeee"))
                        .frame(width: 64, height: 64)
                }
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(hex: "7ba7bc").opacity(0.2))
                        .frame(width: 64, height: 64)
                    Image(systemName: "waveform.circle.fill")
                        .font(.system(size: 30))
                        .foregroundColor(Color(hex: "7ba7bc"))
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(memory.personName.isEmpty ? "Unnamed" : memory.personName)
                    .font(.custom("Georgia", size: 16))
                    .fontWeight(.semibold)
                    .foregroundColor(Color(hex: "444444"))
                if !memory.location.isEmpty {
                    Text(memory.location)
                        .font(.custom("Georgia", size: 13))
                        .foregroundColor(Color(hex: "888888"))
                }
                if !memory.dateTaken.isEmpty {
                    Text(memory.dateTaken)
                        .font(.custom("Georgia", size: 12))
                        .foregroundColor(Color(hex: "aaaaaa"))
                }
            }

            Spacer()

            Image(systemName: memory.type == .photo ? "photo" : "mic")
                .foregroundColor(memory.type == .photo ? Color(hex: "a8c5a0") : Color(hex: "7ba7bc"))
                .font(.system(size: 16))
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white.opacity(0.75))
                .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 3)
        )
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                memoryStore.delete(memory)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .onAppear {
            // Load image off main thread to keep list smooth
            if memory.type == .photo, let filename = memory.imageFilename {
                DispatchQueue.global(qos: .userInitiated).async {
                    let img = ImageFileStorage.load(filename)
                    DispatchQueue.main.async { loadedImage = img }
                }
            }
        }
    }
}

// MARK: - Add Memory View
struct AddMemoryView: View {
    @EnvironmentObject var memoryStore: MemoryStore
    @Environment(\.dismiss) var dismiss

    @State private var memoryType: Memory.MemoryType = .photo
    @State private var selectedImage: UIImage? = nil
    @State private var showPhotoPicker = false
    @State private var personName = ""
    @State private var location = ""
    @State private var activity = ""
    @State private var dateTaken = ""
    @State private var distractors = ""
    @State private var isRecording = false
    @State private var audioRecorder: AVAudioRecorder?
    @State private var recordingURL: URL?
    @State private var recordingDone = false

    var canSave: Bool {
        !personName.isEmpty && (selectedImage != nil || recordingDone)
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {

                    Picker("Type", selection: $memoryType) {
                        Label("Photo", systemImage: "photo").tag(Memory.MemoryType.photo)
                        Label("Voice", systemImage: "mic").tag(Memory.MemoryType.voice)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    if memoryType == .photo {
                        Button { showPhotoPicker = true } label: {
                            if let img = selectedImage {
                                Image(uiImage: img)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(height: 200)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                    .padding(.horizontal)
                            } else {
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color(hex: "f0f0f0"))
                                    .frame(height: 200)
                                    .overlay(
                                        VStack(spacing: 8) {
                                            Image(systemName: "photo.badge.plus")
                                                .font(.system(size: 36))
                                                .foregroundColor(Color(hex: "aaaaaa"))
                                            Text("Tap to choose photo")
                                                .font(.custom("Georgia", size: 14))
                                                .foregroundColor(Color(hex: "aaaaaa"))
                                        }
                                    )
                                    .padding(.horizontal)
                            }
                        }
                    } else {
                        // Voice recorder
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(isRecording
                                          ? Color(hex: "f07080").opacity(0.15)
                                          : Color(hex: "7ba7bc").opacity(0.1))
                                    .frame(width: 120, height: 120)
                                    .scaleEffect(isRecording ? 1.15 : 1.0)
                                    .animation(
                                        .easeInOut(duration: 0.8).repeatForever(autoreverses: true),
                                        value: isRecording
                                    )

                                Button {
                                    isRecording ? stopRecording() : startRecording()
                                } label: {
                                    Image(systemName: isRecording ? "stop.circle.fill" : "mic.circle.fill")
                                        .font(.system(size: 72))
                                        .foregroundColor(isRecording ? Color(hex: "f07080") : Color(hex: "7ba7bc"))
                                }
                            }

                            Text(isRecording
                                 ? "Recording... tap to stop"
                                 : recordingDone ? "✓ Recording saved" : "Tap to record voice")
                                .font(.custom("Georgia", size: 14))
                                .foregroundColor(recordingDone ? Color(hex: "a8c5a0") : Color(hex: "888888"))
                        }
                        .padding()
                    }

                    // Fields
                    VStack(spacing: 14) {
                        SetupField(icon: "person.fill", placeholder: "Person's name (required)", text: $personName, color: Color(hex: "7ba7bc"))

                        if memoryType == .photo {
                            SetupField(icon: "mappin.circle.fill", placeholder: "Where was this? (e.g. Botanic Garden)", text: $location, color: Color(hex: "a8c5a0"))
                            SetupField(icon: "figure.walk", placeholder: "What were they doing?", text: $activity, color: Color(hex: "f0a030"))
                            SetupField(icon: "calendar", placeholder: "When? (e.g. Christmas 2022)", text: $dateTaken, color: Color(hex: "c97b84"))
                        }

                        SetupField(icon: "list.bullet", placeholder: "Wrong answer options (comma separated)", text: $distractors, color: Color(hex: "888888"))
                        Text("e.g. Brother, Sister, Friend — used as wrong answers in the quiz")
                            .font(.custom("Georgia", size: 12))
                            .foregroundColor(Color(hex: "aaaaaa"))
                            .padding(.horizontal, 4)
                    }
                    .padding(.horizontal, 20)

                    // Save button
                    Button { saveMemory() } label: {
                        Text("Save Memory")
                            .font(.custom("Snell Roundhand", size: 22))
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(canSave
                                          ? LinearGradient(
                                              colors: [Color(hex: "a8c5a0"), Color(hex: "7eb8a4")],
                                              startPoint: .leading, endPoint: .trailing)
                                          : LinearGradient(
                                              colors: [Color.gray.opacity(0.4), Color.gray.opacity(0.3)],
                                              startPoint: .leading, endPoint: .trailing))
                            )
                    }
                    .disabled(!canSave)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
                }
                .padding(.top, 20)
            }
            .navigationTitle("Add Memory")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(Color(hex: "7ba7bc"))
                }
            }
        }
        .sheet(isPresented: $showPhotoPicker) {
            ImagePicker(image: $selectedImage)
        }
    }

    func saveMemory() {
        var memory = Memory(type: memoryType)
        memory.personName = personName
        memory.location = location
        memory.activity = activity
        memory.dateTaken = dateTaken
        memory.distractors = distractors
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        if memoryType == .photo, let img = selectedImage {
            // Save image to file — only filename stored in model
            memory.imageFilename = ImageFileStorage.save(img, compressionQuality: 0.7)
        } else if memoryType == .voice, let url = recordingURL {
            // Move recording to permanent Documents location
            memory.voiceFilename = VoiceFileStorage.save(from: url)
        }

        memoryStore.add(memory)
        dismiss()
    }

    func startRecording() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playAndRecord, mode: .default)
        try? session.setActive(true)
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("recording_\(UUID().uuidString).m4a")
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        audioRecorder = try? AVAudioRecorder(url: url, settings: settings)
        audioRecorder?.record()
        recordingURL = url
        isRecording = true
    }

    func stopRecording() {
        audioRecorder?.stop()
        isRecording = false
        recordingDone = true
    }
}

// MARK: - Setup Field
struct SetupField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 22)
            TextField(placeholder, text: $text)
                .font(.custom("Georgia", size: 15))
                .foregroundColor(Color(hex: "444444"))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color(hex: "f5f5f5")))
    }
}
