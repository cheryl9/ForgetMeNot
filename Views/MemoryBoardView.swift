import SwiftUI
import PhotosUI

// MARK: - Memory Board Entry
struct MemoryBoardEntry: Identifiable, Codable {
    var id = UUID()
    var text: String = ""
    // FILE-BASED: filename only — no raw Data blob
    var imageFilename: String? = nil
    var personName: String = ""
    var createdFrom: String = ""  // "manual" or "quiz_wrong"
    var dateCreated: Date = Date()

    // Convenience accessor — loads from disk on demand
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
        // Clean up image file from disk before removing record
        ImageFileStorage.delete(entry.imageFilename)
        entries.removeAll { $0.id == entry.id }
        save()
    }

    private func save() {
        // Only tiny filenames stored — no image blobs
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
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        ZStack {
            Image("memory_wall")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                ZStack {
                    HStack {
                        Button(action: { dismiss() }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(10)
                                .background(Circle().fill(Color.black.opacity(0.2)))
                        }
                        Spacer()
                        Button(action: { showAddSheet = true }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 28))
                                .foregroundColor(.white)
                                .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                        }
                    }
                    .padding(.horizontal, 24)

                    Text("Memory Board")
                        .font(.custom("Snell Roundhand", size: 32))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.3), radius: 6, x: 0, y: 2)
                }
                .padding(.top, 150)
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
                        LazyVGrid(columns: columns, spacing: 24) {
                            ForEach(memoryBoardStore.entries) { entry in
                                HangingMemoryCard(entry: entry)
                                    .onTapGesture { editingEntry = entry }
                            }
                        }
                        .padding(.top, -50)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                    }
                }
            }
        }
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

    var body: some View {
        VStack(spacing: 0) {
            // The sign card
            ZStack {
                Image("memory_sign")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 800)

                VStack(spacing: 14) {
                    // Load image asynchronously — no lag on scroll
                    if let img = loadedImage {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 220, height: 160)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }

                    if !entry.text.isEmpty {
                        Text(entry.text)
                            .font(.custom("Georgia", size: 18))
                            .foregroundColor(Color(hex: "5a3e2b"))
                            .multilineTextAlignment(.center)
                            .lineLimit(5)
                            .padding(.horizontal, 32)
                    }

                    if !entry.personName.isEmpty {
                        Text(entry.personName)
                            .font(.custom("Georgia", size: 16))
                            .foregroundColor(Color(hex: "7ba7bc"))
                            .italic()
                    }
                }
                .frame(width: 380)
                .padding(.top, 80)
            }
        }
        .onAppear {
            // Load image off main thread to keep grid smooth
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
                            // Replace old file, store new filename
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

                        // Photo picker — shows existing or newly picked image
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
            selectedImage = nil  // always start fresh; existing image loads via entry.image
        }
    }
}