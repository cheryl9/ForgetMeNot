import SwiftUI
import AVFoundation

// MARK: - Memory Board Entry
struct MemoryBoardEntry: Identifiable, Codable {
    var id = UUID()
    var text: String = ""
    var imageFilename: String? = nil
    var voiceFilename: String? = nil
    var personName: String = ""
    var createdFrom: String = "manual"
    var dateCreated: Date = Date()
    var entryType: EntryType = .photo

    enum EntryType: String, Codable { case photo, voice }

    var image: UIImage? { ImageFileStorage.load(imageFilename) }
    var voiceURL: URL? { VoiceFileStorage.url(for: voiceFilename) }
}

// MARK: - Memory Board Store
class MemoryBoardStore: ObservableObject {
    @Published var entries: [MemoryBoardEntry] = []
    private var userKey: String = "guest"

    init() {}

    func load(for username: String) {
        userKey = username.lowercased().trimmingCharacters(in: .whitespaces)
        if let data = UserDefaults.standard.data(forKey: "memoryBoard_\(userKey)"),
           let decoded = try? JSONDecoder().decode([MemoryBoardEntry].self, from: data) {
            entries = decoded
        } else { entries = [] }
    }

    func add(_ entry: MemoryBoardEntry) { entries.append(entry); save() }

    func update(_ entry: MemoryBoardEntry) {
        if let idx = entries.firstIndex(where: { $0.id == entry.id }) {
            entries[idx] = entry; save()
        }
    }

    func delete(_ entry: MemoryBoardEntry) {
        ImageFileStorage.delete(entry.imageFilename)
        VoiceFileStorage.delete(entry.voiceFilename)
        entries.removeAll { $0.id == entry.id }
        save()
    }

    private func save() {
        if let data = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(data, forKey: "memoryBoard_\(userKey)")
        }
    }
}

// MARK: - Memory Board View
struct MemoryBoardView: View {
    @EnvironmentObject var memoryBoardStore: MemoryBoardStore
    @Environment(\.dismiss) var dismiss

    @State private var showAddSheet = false
    @State private var editingEntry: MemoryBoardEntry? = nil

    private let rotations: [Double] = [-2.0, 1.5, -1.0, 2.0, -1.5, 1.0, -2.0, 1.5]

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
    ]

    var body: some View {
        ZStack {
            Image("memory_wall")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            Color.black.opacity(0.18)
                .ignoresSafeArea()

            VStack(spacing: 0) {

                // ─── HEADER (Now outside ScrollView) ───
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 40, height: 40)
                            .background(Circle().fill(Color.black.opacity(0.3)))
                    }

                    Spacer()

                    Text("Memory Board")
                        .font(.custom("Snell Roundhand", size: 32))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.4), radius: 4, x: 0, y: 2)

                    Spacer()

                    Button { showAddSheet = true } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 40, height: 40)
                            .background(Circle().fill(Color(hex: "a8c5a0")))
                            .shadow(color: .black.opacity(0.25), radius: 4, x: 0, y: 2)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 120)   // 👈 Adjust this number to move header down
                .padding(.bottom, 20)

                // ─── SCROLLING CONTENT ───
                ScrollView(.vertical, showsIndicators: false) {

                    if memoryBoardStore.entries.isEmpty {
                        VStack(spacing: 14) {
                            Spacer().frame(height: 60)

                            Image(systemName: "photo.on.rectangle.angled")
                                .font(.system(size: 44))
                                .foregroundColor(.white.opacity(0.6))

                            Text("No memories yet")
                                .font(.custom("Snell Roundhand", size: 26))
                                .foregroundColor(.white.opacity(0.9))

                            Text("Tap + to add a photo or voice memory")
                                .font(.custom("Georgia", size: 14))
                                .foregroundColor(.white.opacity(0.65))
                                .multilineTextAlignment(.center)
                        }
                        .padding(.horizontal, 40)
                    } else {
                        LazyVGrid(columns: columns, spacing: 4) {
                            ForEach(Array(memoryBoardStore.entries.enumerated()), id: \.element.id) { idx, entry in
                                MemorySignCard(
                                    entry: entry,
                                    rotation: rotations[idx % rotations.count]
                                )
                                .onTapGesture { editingEntry = entry }
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.bottom, 60)
                    }
                }
            }
        }
        .sheet(isPresented: $showAddSheet) {
            MemoryCardEditView(entry: MemoryBoardEntry(), isNew: true) {
                memoryBoardStore.add($0)
            }
        }
        .sheet(item: $editingEntry) { entry in
            MemoryCardEditView(entry: entry, isNew: false) {
                memoryBoardStore.update($0)
            }
        }
    }
}

// MARK: - Memory Sign Card
struct MemorySignCard: View {
    let entry: MemoryBoardEntry
    let rotation: Double

    @State private var loadedImage: UIImage?
    @State private var isPlayingVoice = false
    @State private var audioPlayer: AVAudioPlayer?

    var body: some View {
        ZStack {
            // Sign image is the whole card background
            Image("memory_sign")
                .resizable()
                .scaledToFit()

            // Content overlaid inside the sign frame - centered
            VStack(spacing: 0) {
                Spacer()
                
                VStack(spacing: 8) {
                    // Photo
                    if entry.entryType == .photo, let img = loadedImage {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: 140)
                            .frame(maxHeight: 65)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .clipped()
                    } else if entry.entryType == .voice {
                        Button { toggleVoice() } label: {
                            VStack(spacing: 3) {
                                Image(systemName: isPlayingVoice ? "stop.circle.fill" : "play.circle.fill")
                                    .font(.system(size: 28))
                                    .foregroundColor(Color(hex: "7ba7bc"))
                                Text(isPlayingVoice ? "Stop" : "Play")
                                    .font(.custom("Georgia", size: 10))
                                    .foregroundColor(Color(hex: "7ba7bc"))
                            }
                        }
                        .buttonStyle(.plain)
                    }

                    // Text note
                    if !entry.text.isEmpty {
                        Text(entry.text)
                            .font(.custom("Georgia", size: 11))
                            .foregroundColor(Color(hex: "3a2a1a"))
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .padding(.horizontal, 20)
                    }

                    // Person tag
                    if !entry.personName.isEmpty {
                        Text("— \(entry.personName)")
                            .font(.custom("Georgia", size: 10))
                            .italic()
                            .foregroundColor(Color(hex: "7ba7bc"))
                    }
                }
                .frame(maxWidth: .infinity)
                
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .rotationEffect(.degrees(rotation))
        .onAppear {
            if entry.entryType == .photo, let fn = entry.imageFilename {
                DispatchQueue.global(qos: .userInitiated).async {
                    let img = ImageFileStorage.load(fn)
                    DispatchQueue.main.async { loadedImage = img }
                }
            }
        }
    }

    func toggleVoice() {
        if isPlayingVoice {
            audioPlayer?.stop()
            isPlayingVoice = false
        } else if let url = VoiceFileStorage.url(for: entry.voiceFilename) {
            audioPlayer = try? AVAudioPlayer(contentsOf: url)
            audioPlayer?.play()
            isPlayingVoice = true
        }
    }
}

// MARK: - Memory Card Edit View
struct MemoryCardEditView: View {
    @Environment(\.dismiss) var dismiss
    @State private var entry: MemoryBoardEntry
    let isNew: Bool
    let onSave: (MemoryBoardEntry) -> Void

    @State private var showPhotoPicker = false
    @State private var selectedImage: UIImage?
    @State private var selectedTab: MemoryBoardEntry.EntryType = .photo

    // Voice
    @State private var isRecording = false
    @State private var audioRecorder: AVAudioRecorder?
    @State private var recordingURL: URL?
    @State private var recordingDone = false
    @State private var audioPlayer: AVAudioPlayer?
    @State private var isPlaying = false

    init(entry: MemoryBoardEntry, isNew: Bool, onSave: @escaping (MemoryBoardEntry) -> Void) {
        _entry = State(initialValue: entry)
        self.isNew = isNew
        self.onSave = onSave
        _selectedTab = State(initialValue: entry.entryType)
    }

    var canSave: Bool { !entry.text.isEmpty || selectedImage != nil || recordingDone || entry.image != nil }

    var body: some View {
        ZStack {
            Color(hex: "f7f3ee").ignoresSafeArea()
            Image("garden_background")
                .resizable().scaledToFill().ignoresSafeArea().opacity(0.06)

            VStack(spacing: 0) {
                // Top bar
                HStack {
                    Button("Cancel") { dismiss() }
                        .font(.custom("Georgia", size: 15))
                        .foregroundColor(Color(hex: "9a8a7a"))
                    Spacer()
                    Text(isNew ? "New Memory" : "Edit Memory")
                        .font(.custom("Snell Roundhand", size: 26))
                        .foregroundColor(Color(hex: "5c4a3a"))
                    Spacer()
                    Button("Save") { saveEntry() }
                        .font(.custom("Georgia", size: 15)).fontWeight(.semibold)
                        .foregroundColor(canSave ? Color(hex: "a8c5a0") : Color(hex: "cccccc"))
                        .disabled(!canSave)
                }
                .padding(.horizontal, 24)
                .padding(.top, 56)
                .padding(.bottom, 16)

                // Tab switcher
                HStack(spacing: 0) {
                    ForEach([("Photo", MemoryBoardEntry.EntryType.photo),
                             ("Voice", .voice)], id: \.0) { label, tab in
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedTab = tab
                                entry.entryType = tab
                            }
                        } label: {
                            Text(label)
                                .font(.custom("Georgia", size: 15))
                                .fontWeight(selectedTab == tab ? .semibold : .regular)
                                .foregroundColor(selectedTab == tab ? Color(hex: "5c4a3a") : Color(hex: "9a8a7a"))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 11)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(selectedTab == tab ? Color(hex: "e8e0d8") : Color.clear)
                                )
                        }
                    }
                }
                .padding(4)
                .background(RoundedRectangle(cornerRadius: 13).fill(Color(hex: "ede8e0")))
                .padding(.horizontal, 24)
                .padding(.bottom, 20)

                ScrollView {
                    VStack(spacing: 18) {
                        // ── Media section ──
                        if selectedTab == .photo {
                            Button { showPhotoPicker = true } label: {
                                if let img = selectedImage ?? entry.image {
                                    Image(uiImage: img)
                                        .resizable().scaledToFill()
                                        .frame(maxWidth: .infinity).frame(height: 200)
                                        .clipShape(RoundedRectangle(cornerRadius: 16))
                                        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 3)
                                } else {
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color(hex: "ede8e0"))
                                        .frame(maxWidth: .infinity).frame(height: 160)
                                        .overlay(
                                            VStack(spacing: 10) {
                                                Image(systemName: "photo.badge.plus")
                                                    .font(.system(size: 34))
                                                    .foregroundColor(Color(hex: "b0a090"))
                                                Text("Tap to add a photo")
                                                    .font(.custom("Georgia", size: 14))
                                                    .foregroundColor(Color(hex: "b0a090"))
                                            }
                                        )
                                }
                            }
                        } else {
                            // Voice recorder UI
                            VStack(spacing: 16) {
                                ZStack {
                                    Circle()
                                        .fill(isRecording
                                              ? Color(hex: "f07080").opacity(0.12)
                                              : Color(hex: "7ba7bc").opacity(0.1))
                                        .frame(width: 160, height: 160)
                                        .scaleEffect(isRecording ? 1.15 : 1.0)
                                        .animation(
                                            isRecording
                                            ? .easeInOut(duration: 0.7).repeatForever(autoreverses: true)
                                            : .default,
                                            value: isRecording
                                        )

                                    Button { isRecording ? stopRecording() : startRecording() } label: {
                                        Image(systemName: isRecording ? "stop.circle.fill" : "mic.circle.fill")
                                            .font(.system(size: 88))
                                            .foregroundColor(isRecording ? Color(hex: "f07080") : Color(hex: "7ba7bc"))
                                    }
                                }

                                Text(isRecording ? "Recording… tap to stop"
                                     : recordingDone ? "✓ Voice memory recorded!"
                                     : "Tap the mic to record")
                                    .font(.custom("Georgia", size: 14))
                                    .foregroundColor(recordingDone ? Color(hex: "a8c5a0") : Color(hex: "9a8a7a"))

                                if recordingDone {
                                    Button { togglePlayback() } label: {
                                        HStack(spacing: 8) {
                                            Image(systemName: isPlaying ? "stop.fill" : "play.fill")
                                            Text(isPlaying ? "Stop" : "Play back")
                                        }
                                        .font(.custom("Georgia", size: 14))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 22).padding(.vertical, 10)
                                        .background(Capsule().fill(Color(hex: "7ba7bc")))
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 28)
                            .background(RoundedRectangle(cornerRadius: 16).fill(Color(hex: "ede8e0")))
                        }

                        // ── Text note ──
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Memory note")
                                .font(.custom("Georgia", size: 13))
                                .foregroundColor(Color(hex: "b0a090"))
                            TextField("Write something to remember…", text: $entry.text, axis: .vertical)
                                .font(.custom("Georgia", size: 16))
                                .foregroundColor(Color(hex: "333333"))
                                .lineLimit(3...6)
                                .padding(14)
                                .background(RoundedRectangle(cornerRadius: 12).fill(Color(hex: "ede8e0")))
                        }

                        // ── Person ──
                        VStack(alignment: .leading, spacing: 6) {
                            Text("About who? (optional)")
                                .font(.custom("Georgia", size: 13))
                                .foregroundColor(Color(hex: "b0a090"))
                            TextField("Person's name", text: $entry.personName)
                                .font(.custom("Georgia", size: 16))
                                .foregroundColor(Color(hex: "333333"))
                                .padding(14)
                                .background(RoundedRectangle(cornerRadius: 12).fill(Color(hex: "ede8e0")))
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            }
        }
        .sheet(isPresented: $showPhotoPicker) { ImagePicker(image: $selectedImage) }
    }

    func saveEntry() {
        var saved = entry
        saved.entryType = selectedTab
        if selectedTab == .photo, let img = selectedImage {
            saved.imageFilename = ImageFileStorage.replace(old: entry.imageFilename, with: img, compressionQuality: 0.75)
        } else if selectedTab == .voice, let url = recordingURL {
            VoiceFileStorage.delete(entry.voiceFilename)
            saved.voiceFilename = VoiceFileStorage.save(from: url)
        }
        onSave(saved)
        dismiss()
    }

    func startRecording() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playAndRecord, mode: .default)
        try? session.setActive(true)
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("memory_\(UUID().uuidString).m4a")
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
        recordingDone = false
    }

    func stopRecording() {
        audioRecorder?.stop()
        isRecording = false
        recordingDone = true
    }

    func togglePlayback() {
        if isPlaying {
            audioPlayer?.stop()
            isPlaying = false
        } else if let url = recordingURL {
            audioPlayer = try? AVAudioPlayer(contentsOf: url)
            audioPlayer?.play()
            isPlaying = true
        }
    }
}