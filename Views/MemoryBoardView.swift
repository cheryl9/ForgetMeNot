import SwiftUI
import PhotosUI

// MARK: - Memory Board Entry
struct MemoryBoardEntry: Identifiable, Codable {
    var id = UUID()
    var text: String = ""
    var imageFilename: String? = nil
    var personName: String = ""
    var createdFrom: String = ""
    var dateCreated: Date = Date()

    var image: UIImage? { ImageFileStorage.load(imageFilename) }
}

// MARK: - Memory Board Store (per-user)
class MemoryBoardStore: ObservableObject {
    @Published var entries: [MemoryBoardEntry] = []
    private var userKey: String = "guest"

    init() {}

    func load(for username: String) {
        userKey = username.lowercased().trimmingCharacters(in: .whitespaces)
        if let data = UserDefaults.standard.data(forKey: "memoryBoard_\(userKey)"),
           let decoded = try? JSONDecoder().decode([MemoryBoardEntry].self, from: data) {
            entries = decoded
        } else {
            entries = []
        }
    }

    func add(_ entry: MemoryBoardEntry) {
        entries.append(entry)
        save()
    }

    func update(_ entry: MemoryBoardEntry) {
        if let idx = entries.firstIndex(where: { $0.id == entry.id }) {
            entries[idx] = entry
            save()
        }
    }

    func delete(_ entry: MemoryBoardEntry) {
        ImageFileStorage.delete(entry.imageFilename)
        entries.removeAll { $0.id == entry.id }
        save()
    }

    private func save() {
        if let data = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(data, forKey: "memoryBoard_\(userKey)")
        }
    }
}

// MARK: - Memory Board Page
struct MemoryBoardView: View {
    @EnvironmentObject var memoryBoardStore: MemoryBoardStore
    @Environment(\.dismiss) var dismiss

    @State private var showAddSheet = false
    @State private var editingEntry: MemoryBoardEntry? = nil

    let columns = [
        GridItem(.flexible(), spacing: 24),
        GridItem(.flexible(), spacing: 24)
    ]

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Image("memory_wall")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Button(action: { dismiss() }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(10)
                                .background(Circle().fill(Color.black.opacity(0.25)))
                                .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
                        }

                        Spacer()

                        Text("Memory Board")
                            .font(.custom("Snell Roundhand", size: 32))
                            .fontWeight(.semibold)
                            .foregroundColor(Color(hex: "5c4a3a"))

                        Spacer()

                        Button(action: { showAddSheet = true }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 30))
                                .foregroundColor(.white)
                                .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                        }
                    }
                    .padding(.horizontal, 28)
                    .padding(.top, geo.safeAreaInsets.top + 16)
                    .padding(.bottom, 20)

                    if memoryBoardStore.entries.isEmpty {
                        Spacer()
                        VStack(spacing: 12) {
                            Image(systemName: "square.and.pencil")
                                .font(.system(size: 44))
                                .foregroundColor(.white.opacity(0.6))
                            Text("No memories yet")
                                .font(.custom("Georgia", size: 18))
                                .foregroundColor(.white.opacity(0.8))
                            Text("Tap + to add your first memory")
                                .font(.custom("Georgia", size: 14))
                                .foregroundColor(.white.opacity(0.6))
                        }
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVGrid(columns: columns, spacing: 32) {
                                ForEach(memoryBoardStore.entries) { entry in
                                    HangingMemoryCard(entry: entry)
                                        .onTapGesture { editingEntry = entry }
                                }
                            }
                            .padding(.horizontal, 28)
                            .padding(.bottom, geo.safeAreaInsets.bottom + 40)
                        }
                    }
                }
            }
        }
        .ignoresSafeArea()
        .sheet(isPresented: $showAddSheet) {
            MemoryCardEditView(entry: MemoryBoardEntry(), isNew: true) { saved in
                memoryBoardStore.add(saved)
            }
        }
        .sheet(item: $editingEntry) { entry in
            MemoryCardEditView(entry: entry, isNew: false) { saved in
                memoryBoardStore.update(saved)
            }
        }
    }
}

// MARK: - Hanging Memory Card
struct HangingMemoryCard: View {
    let entry: MemoryBoardEntry
    @State private var loadedImage: UIImage?

    let cardWidth: CGFloat = 300
    let cardHeight: CGFloat = 360

    var body: some View {
        VStack(spacing: 0) {
            // Hanging string
            Rectangle()
                .fill(Color(hex: "b0a090").opacity(0.8))
                .frame(width: 2, height: 24)

            // Card
            ZStack(alignment: .top) {
                // Sign background image
                Image("memory_sign")
                    .resizable()
                    .scaledToFill()
                    .frame(width: cardWidth, height: cardHeight)
                    .clipped()

                // Content overlaid on sign
                VStack(spacing: 10) {
                    if let img = loadedImage {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFill()
                            .frame(width: cardWidth * 0.75, height: cardHeight * 0.5)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .shadow(color: .black.opacity(0.12), radius: 4, x: 0, y: 2)
                    }

                    if !entry.text.isEmpty {
                        Text(entry.text)
                            .font(.custom("Georgia", size: 14))
                            .foregroundColor(Color(hex: "5a3e2b"))
                            .multilineTextAlignment(.center)
                            .lineLimit(3)
                            .frame(width: cardWidth * 0.75)
                    }

                    if !entry.personName.isEmpty {
                        Text(entry.personName)
                            .font(.custom("Georgia", size: 13))
                            .foregroundColor(Color(hex: "7ba7bc"))
                            .italic()
                    }
                }
                .padding(.top, 48)
            }
        }
        .onAppear {
            if let filename = entry.imageFilename {
                DispatchQueue.global(qos: .userInitiated).async {
                    let img = ImageFileStorage.load(filename)
                    DispatchQueue.main.async { loadedImage = img }
                }
            }
        }
    }
}

// MARK: - Memory Card Edit Sheet
struct MemoryCardEditView: View {
    @Environment(\.dismiss) var dismiss
    @State private var entry: MemoryBoardEntry
    let isNew: Bool
    let onSave: (MemoryBoardEntry) -> Void

    @State private var showPhotoPicker = false
    @State private var selectedImage: UIImage?

    init(entry: MemoryBoardEntry, isNew: Bool, onSave: @escaping (MemoryBoardEntry) -> Void) {
        self._entry = State(initialValue: entry)
        self.isNew = isNew
        self.onSave = onSave
    }

    var body: some View {
        ZStack {
            Image("garden_background")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
            Color.white.opacity(0.5).ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Button("Cancel") { dismiss() }
                        .font(.custom("Georgia", size: 15))
                        .foregroundColor(Color(hex: "7ba7bc"))
                    Spacer()
                    Text(isNew ? "New Memory" : "Edit Memory")
                        .font(.custom("Snell Roundhand", size: 22))
                        .foregroundColor(Color(hex: "7ba7bc"))
                    Spacer()
                    Button("Save") {
                        var saved = entry
                        if let img = selectedImage {
                            saved.imageFilename = ImageFileStorage.replace(
                                old: entry.imageFilename,
                                with: img,
                                compressionQuality: 0.5
                            )
                        }
                        onSave(saved)
                        dismiss()
                    }
                    .font(.custom("Georgia", size: 15))
                    .fontWeight(.semibold)
                    .foregroundColor(Color(hex: "a8c5a0"))
                }
                .padding(.horizontal, 24)
                .padding(.top, 60)
                .padding(.bottom, 20)

                ScrollView {
                    VStack(spacing: 24) {
                        Button { showPhotoPicker = true } label: {
                            ZStack {
                                if let img = selectedImage ?? entry.image {
                                    Image(uiImage: img)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(height: 200)
                                        .clipShape(RoundedRectangle(cornerRadius: 20))
                                } else {
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(Color.white.opacity(0.6))
                                        .frame(height: 200)
                                        .overlay(
                                            VStack(spacing: 10) {
                                                Image(systemName: "photo.badge.plus")
                                                    .font(.system(size: 36))
                                                    .foregroundColor(Color(hex: "aaaaaa"))
                                                Text("Add a photo (optional)")
                                                    .font(.custom("Georgia", size: 14))
                                                    .foregroundColor(Color(hex: "aaaaaa"))
                                            }
                                        )
                                }
                            }
                        }
                        .padding(.horizontal, 24)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Your memory")
                                .font(.custom("Georgia", size: 13))
                                .foregroundColor(Color(hex: "aaaaaa"))
                                .padding(.horizontal, 4)
                            TextField("Write your memory here...", text: $entry.text, axis: .vertical)
                                .font(.custom("Georgia", size: 16))
                                .foregroundColor(Color(hex: "333333"))
                                .lineLimit(4...8)
                                .padding(16)
                                .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.8)))
                        }
                        .padding(.horizontal, 24)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("About who? (optional)")
                                .font(.custom("Georgia", size: 13))
                                .foregroundColor(Color(hex: "aaaaaa"))
                                .padding(.horizontal, 4)
                            TextField("Person's name", text: $entry.personName)
                                .font(.custom("Georgia", size: 16))
                                .foregroundColor(Color(hex: "333333"))
                                .padding(16)
                                .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.8)))
                        }
                        .padding(.horizontal, 24)
                    }
                    .padding(.bottom, 40)
                }
            }
        }
        .sheet(isPresented: $showPhotoPicker) {
            ImagePicker(image: $selectedImage)
        }
        .onAppear {
            selectedImage = nil
        }
    }
}