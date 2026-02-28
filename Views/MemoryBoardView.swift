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
    @EnvironmentObject var musicPlayer: AmbientMusicPlayer

    @State private var showAddSheet = false
    @State private var editingEntry: MemoryBoardEntry? = nil
    @State private var showDeleteConfirm = false
    @State private var entryToDelete: MemoryBoardEntry? = nil

    private let rotations: [Double] = [-2.0, 1.5, -1.0, 2.0, -1.5, 1.0, -2.0, 1.5]

    var body: some View {
        GeometryReader { geo in
            let availableWidth = max(220, geo.size.width - 16)
            let columnCount = min(4, max(2, Int(availableWidth / 150)))
            let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: columnCount)

            ZStack {
                Image("memory_wall")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()

                Color.black.opacity(0.18)
                    .ignoresSafeArea()

                VStack(spacing: 0) {

                    // ─── HEADER ───
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
                            .font(.custom("Snell Roundhand", size: geo.size.width > 700 ? 36 : 32))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.4), radius: 4, x: 0, y: 2)

                        Spacer()

                        HStack(spacing: 12) {
                            MusicToggleButton(musicPlayer: musicPlayer)
                            
                            Button { showAddSheet = true } label: {
                                Image(systemName: "plus")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(width: 40, height: 40)
                                    .background(Circle().fill(Color(hex: "a8c5a0")))
                                    .shadow(color: .black.opacity(0.25), radius: 4, x: 0, y: 2)
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, geo.safeAreaInsets.top + 32)
                    .padding(.bottom, 16)

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
                            LazyVGrid(columns: columns, spacing: 0) {
                                ForEach(Array(memoryBoardStore.entries.enumerated()), id: \.element.id) { idx, entry in
                                    MemorySignCard(
                                        entry: entry,
                                        rotation: rotations[idx % rotations.count]
                                    )
                                    .onTapGesture { editingEntry = entry }
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            entryToDelete = entry
                                            showDeleteConfirm = true
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 4)
                            .padding(.bottom, geo.safeAreaInsets.bottom + 24)
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showAddSheet) {
            MemoryCardEditView(entry: MemoryBoardEntry(), isNew: true, onSave: {
                memoryBoardStore.add($0)
            })
        }
        .sheet(item: $editingEntry) { entry in
            MemoryCardEditView(entry: entry, isNew: false, onSave: {
                memoryBoardStore.update($0)
            }, onDelete: {
                memoryBoardStore.delete($0)
            })
        }
        .alert("Delete Memory?", isPresented: $showDeleteConfirm) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let entry = entryToDelete {
                    memoryBoardStore.delete(entry)
                    entryToDelete = nil
                }
            }
        } message: {
            Text("This memory will be permanently deleted.")
        }
    }
}

// MARK: - Memory Sign Card
struct MemorySignCard: View {
    let entry: MemoryBoardEntry
    let rotation: Double

    @State private var loadedImage: UIImage?
    @State private var isPlayingVoice = false
    @State private var audioPlayer: AudioPlayerWrapper?

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Image("memory_sign")
                    .resizable()
                    .scaledToFit()
                    .frame(width: geo.size.width, height: geo.size.height)

                // The sign image has a hanging chain at top (~30% of height).
                // The oval board occupies the lower portion.
                // offset(y: 14%) moves content down from center into the oval.
                VStack(spacing: 6) {
                    if entry.entryType == .photo, let img = loadedImage {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFill()
                            .frame(width: geo.size.width * 0.52, height: geo.size.height * 0.28)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .clipped()
                    } else if entry.entryType == .voice {
                        Button { toggleVoice() } label: {
                            VStack(spacing: 3) {
                                Image(systemName: isPlayingVoice ? "stop.circle.fill" : "play.circle.fill")
                                    .font(.system(size: geo.size.width * 0.14))
                                    .foregroundColor(Color(hex: "7ba7bc"))
                                Text(isPlayingVoice ? "Stop" : "Play")
                                    .font(.custom("Georgia", size: 10))
                                    .foregroundColor(Color(hex: "7ba7bc"))
                            }
                        }
                        .buttonStyle(.plain)
                    }

                    if !entry.text.isEmpty {
                        Text(entry.text)
                            .font(.custom("Georgia", size: 11))
                            .foregroundColor(Color(hex: "3a2a1a"))
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .frame(width: geo.size.width * 0.65)
                    }

                    if !entry.personName.isEmpty {
                        Text("— \(entry.personName)")
                            .font(.custom("Georgia", size: 10))
                            .italic()
                            .foregroundColor(Color(hex: "7ba7bc"))
                    }
                }
                .offset(y: geo.size.height * 0.14)
            }
        }
        .aspectRatio(0.85, contentMode: .fit)
        .rotationEffect(.degrees(rotation))
        .onAppear {
            if entry.entryType == .photo, let fn = entry.imageFilename {
                DispatchQueue.global(qos: .userInitiated).async {
                    let img = ImageFileStorage.load(fn)
                    DispatchQueue.main.async { loadedImage = img }
                }
            }
        }
        .onDisappear {
            audioPlayer?.stop()
        }
    }

    func toggleVoice() {
        if isPlayingVoice {
            audioPlayer?.stop()
            isPlayingVoice = false
        } else if let url = VoiceFileStorage.url(for: entry.voiceFilename) {
            audioPlayer = AudioPlayerWrapper(url: url, onFinish: { isPlayingVoice = false })
            audioPlayer?.play()
            isPlayingVoice = true
        }
    }
}

// MARK: - Audio Player Wrapper
class AudioPlayerWrapper: NSObject, AVAudioPlayerDelegate {
    private var player: AVAudioPlayer?
    private var onFinish: (() -> Void)?
    
    init(url: URL, onFinish: @escaping () -> Void) {
        super.init()
        self.onFinish = onFinish
        do {
            // Check if file exists first
            guard FileManager.default.fileExists(atPath: url.path) else {
                print("Audio file not found at: \(url.path)")
                return
            }
            
            // Set up audio session - use .playback with .mixWithOthers to allow ambient music
            let session = AVAudioSession.sharedInstance()
            do {
                try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
                try session.setActive(true, options: .notifyOthersOnDeactivation)
            } catch {
                // Audio session might be in use - that's okay, continue anyway
                print("Audio session note: \(error.localizedDescription)")
            }
            
            // Initialize player
            player = try AVAudioPlayer(contentsOf: url)
            player?.delegate = self
            player?.volume = 1.0
            player?.prepareToPlay()
            
            print("Audio prepared: \(url.lastPathComponent), duration: \(player?.duration ?? 0)s")
        } catch let error as NSError {
            print("Audio player error: \(error.localizedDescription)")
        }
    }
    
    func play() {
        guard let player = player else {
            print("No player available - player is nil")
            return
        }
        let played = player.play()
        print("Play called - result: \(played), isPlaying: \(player.isPlaying)")
    }
    
    func stop() {
        player?.stop()
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        print("Playback finished - success: \(flag)")
        onFinish?()
    }
}

// MARK: - Memory Card Edit View
struct MemoryCardEditView: View {
    @Environment(\.dismiss) var dismiss
    @State private var entry: MemoryBoardEntry
    let isNew: Bool
    let onSave: (MemoryBoardEntry) -> Void
    let onDelete: ((MemoryBoardEntry) -> Void)?

    @State private var showPhotoPicker = false
    @State private var selectedImage: UIImage?
    @State private var selectedTab: MemoryBoardEntry.EntryType = .photo
    @State private var showDeleteConfirm = false

    // Voice
    @State private var isRecording = false
    @State private var audioRecorder: AVAudioRecorder?
    @State private var recordingURL: URL?
    @State private var recordingDone = false
    @State private var audioPlayer: AudioPlayerWrapper?
    @State private var isPlaying = false

    init(entry: MemoryBoardEntry, isNew: Bool, onSave: @escaping (MemoryBoardEntry) -> Void, onDelete: ((MemoryBoardEntry) -> Void)? = nil) {
        _entry = State(initialValue: entry)
        self.isNew = isNew
        self.onSave = onSave
        self.onDelete = onDelete
        _selectedTab = State(initialValue: entry.entryType)
    }

    var canSave: Bool { !entry.text.isEmpty || selectedImage != nil || recordingDone || entry.image != nil }

    var body: some View {
        ZStack {
            Color(hex: "f7f3ee").ignoresSafeArea()
            Image("rock_background")
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
                    HStack(spacing: 12) {
                        if !isNew {
                            Button(role: .destructive) { showDeleteConfirm = true } label: {
                                Image(systemName: "trash")
                                    .font(.custom("Georgia", size: 15))
                                    .foregroundColor(Color(hex: "d97070"))
                            }
                        }
                        Button("Save") { saveEntry() }
                            .font(.custom("Georgia", size: 15)).fontWeight(.semibold)
                            .foregroundColor(canSave ? Color(hex: "a8c5a0") : Color(hex: "cccccc"))
                            .disabled(!canSave)
                    }
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
                                        .clipped()
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
        .fullScreenCover(isPresented: $showPhotoPicker) {
            CameraPicker(image: $selectedImage, sourceType: .photoLibrary)
                .ignoresSafeArea()
        }
        .alert("Delete Memory?", isPresented: $showDeleteConfirm) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                onDelete?(entry)
                dismiss()
            }
        } message: {
            Text("This memory will be permanently deleted.")
        }
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
        let performRecording = {
            let url = FileManager.default.temporaryDirectory
                .appendingPathComponent("memory_\(UUID().uuidString).m4a")
            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44100,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.medium.rawValue
            ]
            do {
                // Set up audio session for recording
                let session = AVAudioSession.sharedInstance()
                do {
                    try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .mixWithOthers])
                    try session.setActive(true, options: .notifyOthersOnDeactivation)
                } catch {
                    print("Audio session configured elsewhere, continuing: \(error.localizedDescription)")
                }
                
                let recorder = try AVAudioRecorder(url: url, settings: settings)
                recorder.prepareToRecord()
                recorder.record()
                DispatchQueue.main.async {
                    self.audioRecorder = recorder
                    self.recordingURL = url
                    self.isRecording = true
                    self.recordingDone = false
                }
                print("✅ Recording started successfully")
            } catch let error as NSError {
                print("❌ Recording failed: \(error.localizedDescription)")
                print("   Error code: \(error.code), domain: \(error.domain)")
            }
        }
        
        #if os(iOS)
        if #available(iOS 17.0, macCatalyst 17.0, *) {
            AVAudioApplication.requestRecordPermission { granted in
                if granted {
                    performRecording()
                } else {
                    print("Mic permission denied")
                }
            }
        } else {
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                if granted {
                    performRecording()
                } else {
                    print("Mic permission denied")
                }
            }
        }
        #else
        performRecording()
        #endif
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
            print("Playing audio from: \(url.lastPathComponent)")
            audioPlayer = AudioPlayerWrapper(url: url, onFinish: { isPlaying = false })
            audioPlayer?.play()
            isPlaying = true
        } else {
            print("No recording URL available")
        }
    }
}
