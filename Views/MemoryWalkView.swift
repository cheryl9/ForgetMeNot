import SwiftUI
import AVFoundation

// ─────────────────────────────────────────────
// MARK: - UIImage EXIF orientation fix
// ─────────────────────────────────────────────
extension UIImage {
    func fixedOrientation() -> UIImage {
        guard imageOrientation != .up else { return self }
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        draw(in: CGRect(origin: .zero, size: size))
        let normalized = UIGraphicsGetImageFromCurrentImageContext() ?? self
        UIGraphicsEndImageContext()
        return normalized
    }
}

// ─────────────────────────────────────────────
// MARK: - Image Picker (photo library)
// ─────────────────────────────────────────────
struct CameraPicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) var dismiss

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.delegate = context.coordinator
        picker.allowsEditing = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: CameraPicker
        init(_ parent: CameraPicker) { self.parent = parent }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            if let raw = info[.originalImage] as? UIImage {
                parent.image = raw.fixedOrientation()
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// ─────────────────────────────────────────────
// MARK: - Memory Walk View
// ─────────────────────────────────────────────
struct MemoryWalkView: View {
    @EnvironmentObject var memoryWalkStore: MemoryWalkStore
    @EnvironmentObject var onboardingStore: OnboardingStore
    @Environment(\.dismiss) var dismiss

    @State private var showSetup = false
    @State private var appeared = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Image("room_background")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
                    .ignoresSafeArea()
                Color.white.opacity(0.35).ignoresSafeArea()

                VStack(spacing: 0) {
                    // ── Header ──
                    HStack {
                        Button { dismiss() } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(Color(hex: "5c4a3a"))
                                .frame(width: 44, height: 44)
                                .background(Circle().fill(Color.white.opacity(0.7)))
                                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                        }

                        Spacer()

                        VStack(spacing: 4) {
                            Text("Memory Walk")
                                .font(.custom("Snell Roundhand", size: 32))
                                .foregroundColor(Color(hex: "5c4a3a"))
                                .shadow(color: .white.opacity(0.8), radius: 4, x: 0, y: 1)
                            Text("Tap a room to revisit your reminders")
                                .font(.custom("Georgia", size: 13))
                                .foregroundColor(Color(hex: "9a8a7a"))
                        }

                        Spacer()

                        Button { showSetup = true } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(Circle().fill(Color(hex: "a8c5a0")))
                                .shadow(color: Color(hex: "a8c5a0").opacity(0.4), radius: 6, x: 0, y: 3)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, geo.safeAreaInsets.top + 30)
                    .padding(.bottom, 24)

                    // ── Room Cards ──
                    if memoryWalkStore.rooms.isEmpty {
                        Spacer()
                        EmptyWalkView { showSetup = true }
                        Spacer()
                    } else {
                        ScrollView(.vertical, showsIndicators: false) {
                            VStack(spacing: 24) {
                                ForEach(Array(memoryWalkStore.rooms.enumerated()), id: \.element.id) { idx, room in
                                    NavigationLink(destination:
                                        RoomDetailView(room: room)
                                            .environmentObject(memoryWalkStore)
                                            .environmentObject(onboardingStore)
                                    ) {
                                        RoomCardView(room: room, index: idx)
                                            .scaleEffect(appeared ? 1 : 0.92)
                                            .opacity(appeared ? 1 : 0)
                                            .animation(
                                                .spring(response: 0.5, dampingFraction: 0.75)
                                                    .delay(Double(idx) * 0.08),
                                                value: appeared
                                            )
                                    }
                                    .buttonStyle(.plain)
                                }

                                Button { showSetup = true } label: {
                                    HStack(spacing: 10) {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.system(size: 20))
                                            .foregroundColor(Color(hex: "a8c5a0"))
                                        Text("Add another room")
                                            .font(.custom("Georgia", size: 16))
                                            .foregroundColor(Color(hex: "7ba7bc"))
                                    }
                                    .padding(.vertical, 20)
                                    .frame(maxWidth: .infinity)
                                    .background(
                                        RoundedRectangle(cornerRadius: 20)
                                            .fill(Color.white.opacity(0.6))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 20)
                                                    .strokeBorder(
                                                        style: StrokeStyle(lineWidth: 1.5, dash: [6])
                                                    )
                                                    .foregroundColor(Color(hex: "a8c5a0").opacity(0.5))
                                            )
                                    )
                                }
                                .padding(.horizontal, 24)
                                .padding(.bottom, geo.safeAreaInsets.bottom + 30)
                            }
                            .padding(.horizontal, 24)
                        }
                    }
                }
            }
        }
        .ignoresSafeArea()
        .navigationBarHidden(true)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.75)) { appeared = true }
        }
        .sheet(isPresented: $showSetup) {
            RoomSetupView { newRoom in
                memoryWalkStore.addRoom(newRoom)
            }
            .environmentObject(onboardingStore)
        }
    }
}

// ─────────────────────────────────────────────
// MARK: - Room Card
// ─────────────────────────────────────────────
struct RoomCardView: View {
    let room: MemoryRoom
    let index: Int
    @State private var loadedImage: UIImage?

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            Group {
                if let img = loadedImage {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                } else {
                    Rectangle()
                        .fill(Color(hex: "e8e0d8"))
                        .overlay(
                            Image(systemName: "photo")
                                .font(.system(size: 40))
                                .foregroundColor(Color(hex: "b0a090"))
                        )
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 240)
            .clipShape(RoundedRectangle(cornerRadius: 24))

            LinearGradient(
                colors: [.clear, .black.opacity(0.6)],
                startPoint: .center,
                endPoint: .bottom
            )
            .clipShape(RoundedRectangle(cornerRadius: 24))

            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(room.roomName)
                        .font(.custom("Snell Roundhand", size: 28))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.4), radius: 2, x: 0, y: 1)
                    if !room.anchors.isEmpty {
                        HStack(spacing: 5) {
                            Image(systemName: "mappin.circle.fill")
                                .font(.system(size: 13))
                                .foregroundColor(Color(hex: "a8c5a0"))
                            Text("\(room.anchors.count) reminder\(room.anchors.count == 1 ? "" : "s")")
                                .font(.custom("Georgia", size: 14))
                                .foregroundColor(.white.opacity(0.9))
                        }
                    }
                }
                Spacer()
                Image(systemName: "chevron.right.circle.fill")
                    .font(.system(size: 26))
                    .foregroundColor(.white.opacity(0.75))
                    .padding(.bottom, 2)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 18)
        }
        .shadow(color: .black.opacity(0.15), radius: 16, x: 0, y: 8)
        .onAppear {
            DispatchQueue.global(qos: .userInitiated).async {
                let img = ImageFileStorage.load(room.imageFilename)
                DispatchQueue.main.async { loadedImage = img }
            }
        }
    }
}

// ─────────────────────────────────────────────
// MARK: - Empty Walk View
// ─────────────────────────────────────────────
struct EmptyWalkView: View {
    let onAdd: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Text("No rooms yet")
                .font(.custom("Snell Roundhand", size: 32))
                .foregroundColor(Color(hex: "5c4a3a"))
            Text("Add a photo of a room in your home\nand tag reminders to familiar objects")
                .font(.custom("Georgia", size: 16))
                .foregroundColor(Color(hex: "9a8a7a"))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
            Button(action: onAdd) {
                HStack(spacing: 10) {
                    Image(systemName: "plus.circle.fill")
                    Text("Add a Room")
                }
                .font(.custom("Georgia", size: 17)).fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.horizontal, 32).padding(.vertical, 16)
                .background(
                    Capsule().fill(
                        LinearGradient(
                            colors: [Color(hex: "7ba7bc"), Color(hex: "a8c5a0")],
                            startPoint: .leading, endPoint: .trailing
                        )
                    )
                    .shadow(color: Color(hex: "7ba7bc").opacity(0.4), radius: 10, x: 0, y: 5)
                )
            }
        }
        .padding(40)
        .background(
            RoundedRectangle(cornerRadius: 32)
                .fill(Color.white.opacity(0.8))
                .shadow(color: .black.opacity(0.08), radius: 24, x: 0, y: 8)
        )
        .padding(.horizontal, 32)
    }
}

// ─────────────────────────────────────────────
// MARK: - Room Detail View
// ─────────────────────────────────────────────
struct RoomDetailView: View {
    let room: MemoryRoom
    @EnvironmentObject var memoryWalkStore: MemoryWalkStore
    @EnvironmentObject var onboardingStore: OnboardingStore
    @Environment(\.dismiss) var dismiss

    @State private var loadedImage: UIImage?
    @State private var selectedAnchor: MemoryAnchor? = nil
    @State private var showEditMode = false
    @State private var showDeleteConfirm = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color(hex: "f0ebe4").ignoresSafeArea()

                VStack(spacing: 0) {
                    // ── Header ──
                    HStack {
                        Button { dismiss() } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(Color(hex: "5c4a3a"))
                                .frame(width: 44, height: 44)
                                .background(Circle().fill(Color.white.opacity(0.85)))
                                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                        }

                        Spacer()

                        Text(room.roomName)
                            .font(.custom("Snell Roundhand", size: 28))
                            .foregroundColor(Color(hex: "5c4a3a"))

                        Spacer()

                        Menu {
                            Button { showEditMode = true } label: {
                                Label("Edit Reminders", systemImage: "pencil")
                            }
                            Button(role: .destructive) {
                                showDeleteConfirm = true
                            } label: {
                                Label("Delete Room", systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle.fill")
                                .font(.system(size: 28))
                                .foregroundColor(Color(hex: "b0a090"))
                                .frame(width: 44, height: 44)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, geo.safeAreaInsets.top + 12)
                    .padding(.bottom, 16)

                    // ── Photo with pins ──
                    if let img = loadedImage {
                        let containerWidth = geo.size.width - 32
                        let imgHeight = containerWidth * (img.size.height / img.size.width)

                        ScrollView(.vertical, showsIndicators: false) {
                            ZStack {
                                Image(uiImage: img)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: containerWidth, height: imgHeight)
                                    .cornerRadius(20)
                                    .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 6)

                                ForEach(room.anchors) { anchor in
                                    PinView(isSelected: selectedAnchor?.id == anchor.id)
                                        .position(
                                            x: anchor.x * containerWidth,
                                            y: anchor.y * imgHeight
                                        )
                                        .onTapGesture {
                                            withAnimation(.spring(response: 0.4, dampingFraction: 0.65)) {
                                                selectedAnchor = selectedAnchor?.id == anchor.id ? nil : anchor
                                            }
                                        }
                                }
                            }
                            .frame(width: containerWidth, height: imgHeight)
                            .padding(.horizontal, 16)

                            if selectedAnchor == nil && !room.anchors.isEmpty {
                                HStack(spacing: 8) {
                                    Image(systemName: "hand.tap.fill")
                                        .foregroundColor(Color(hex: "7ba7bc"))
                                    Text("Tap a glowing pin to see your reminder")
                                        .font(.custom("Georgia", size: 15))
                                        .foregroundColor(Color(hex: "9a8a7a"))
                                }
                                .padding(.vertical, 16)
                                .padding(.horizontal, 24)
                                .background(
                                    Capsule().fill(Color.white.opacity(0.8))
                                        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 3)
                                )
                                .padding(.top, 20)
                                .padding(.bottom, geo.safeAreaInsets.bottom + 30)
                            }
                        }
                    } else {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color(hex: "e8e0d8"))
                            .frame(height: 300)
                            .overlay(ProgressView())
                            .padding(.horizontal, 16)
                        Spacer()
                    }
                }

                // ── Reminder card overlay ──
                if let anchor = selectedAnchor {
                    Color.black.opacity(0.35)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(.spring()) { selectedAnchor = nil }
                        }

                    ReminderCardView(
                        anchor: anchor,
                        people: onboardingStore.people,
                        onDismiss: {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                selectedAnchor = nil
                            }
                        }
                    )
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal: .move(edge: .bottom).combined(with: .opacity)
                    ))
                    .zIndex(10)
                }
            }
        }
        .ignoresSafeArea(edges: .bottom)
        .navigationBarHidden(true)
        .onAppear {
            DispatchQueue.global(qos: .userInitiated).async {
                let img = ImageFileStorage.load(room.imageFilename)
                DispatchQueue.main.async { loadedImage = img }
            }
        }
        .sheet(isPresented: $showEditMode) {
            RoomSetupView(existingRoom: room) { updated in
                memoryWalkStore.updateRoom(updated)
            }
            .environmentObject(onboardingStore)
        }
        .confirmationDialog(
            "Delete \"\(room.roomName)\"?",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete Room", role: .destructive) {
                memoryWalkStore.deleteRoom(room)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently remove the room and all its reminders.")
        }
    }
}

// ─────────────────────────────────────────────
// MARK: - Pin View
// ─────────────────────────────────────────────
struct PinView: View {
    let isSelected: Bool
    @State private var pulsing = false

    var body: some View {
        ZStack {
            Circle()
                .fill(Color(hex: "7ba7bc").opacity(0.22))
                .frame(width: pulsing ? 52 : 36, height: pulsing ? 52 : 36)
                .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: pulsing)
            Circle()
                .fill(Color(hex: "7ba7bc").opacity(0.38))
                .frame(width: 28, height: 28)
            Circle()
                .fill(
                    LinearGradient(
                        colors: isSelected
                            ? [Color(hex: "f07080"), Color(hex: "c0392b")]
                            : [Color(hex: "7ba7bc"), Color(hex: "5a8fa8")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 20, height: 20)
                .shadow(color: .black.opacity(0.28), radius: 3, x: 0, y: 2)
        }
        .scaleEffect(isSelected ? 1.25 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.5), value: isSelected)
        .onAppear { pulsing = true }
    }
}

// ─────────────────────────────────────────────
// MARK: - Reminder Card View
// ─────────────────────────────────────────────
struct ReminderCardView: View {
    let anchor: MemoryAnchor
    let people: [PersonProfile]
    let onDismiss: () -> Void

    @State private var player: AVAudioPlayer?
    @State private var isPlaying = false
    @State private var appeared = false

    var linkedPerson: PersonProfile? {
        guard let name = anchor.linkedPersonName else { return nil }
        return people.first { $0.name == name }
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 22) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color(hex: "dddddd"))
                    .frame(width: 44, height: 4)
                    .padding(.top, 14)

                if !anchor.objectLabel.isEmpty {
                    Text(anchor.objectLabel.uppercased())
                        .font(.custom("Georgia", size: 12))
                        .tracking(2.5)
                        .foregroundColor(Color(hex: "b0a090"))
                }

                Text(anchor.reminderText)
                    .font(.custom("Georgia", size: 26))
                    .fontWeight(.semibold)
                    .foregroundColor(Color(hex: "3a2a1a"))
                    .multilineTextAlignment(.center)
                    .lineSpacing(5)
                    .padding(.horizontal, 8)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 14)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.1), value: appeared)

                if let person = linkedPerson {
                    HStack(spacing: 12) {
                        if let img = person.image {
                            Image(uiImage: img)
                                .resizable().scaledToFill()
                                .frame(width: 40, height: 40)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color(hex: "a8c5a0"), lineWidth: 2))
                        } else {
                            Circle()
                                .fill(Color(hex: "7ba7bc").opacity(0.2))
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Text(person.name.prefix(1).uppercased())
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(Color(hex: "7ba7bc"))
                                )
                        }
                        VStack(alignment: .leading, spacing: 3) {
                            Text(person.name)
                                .font(.custom("Georgia", size: 15)).fontWeight(.semibold)
                                .foregroundColor(Color(hex: "5c4a3a"))
                            Text(person.relationship)
                                .font(.custom("Georgia", size: 13))
                                .foregroundColor(Color(hex: "9a8a7a"))
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 20).padding(.vertical, 12)
                    .background(RoundedRectangle(cornerRadius: 14).fill(Color(hex: "f0f8f0")))
                    .padding(.horizontal, 4)
                }

                if anchor.voiceURL != nil {
                    Button { toggleVoice() } label: {
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(isPlaying ? Color(hex: "f07080") : Color(hex: "7ba7bc"))
                                    .frame(width: 48, height: 48)
                                Image(systemName: isPlaying ? "stop.fill" : "play.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(.white)
                            }
                            Text(isPlaying ? "Stop voice reminder" : "Play voice reminder")
                                .font(.custom("Georgia", size: 16))
                                .foregroundColor(Color(hex: "5c4a3a"))
                            Spacer()
                        }
                        .padding(.horizontal, 16).padding(.vertical, 12)
                        .background(RoundedRectangle(cornerRadius: 16).fill(Color(hex: "e8f4f8")))
                    }
                }

                Button(action: onDismiss) {
                    HStack(spacing: 8) {
                        Text("Got it")
                            .font(.custom("Georgia", size: 24))
                            .fontWeight(.bold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        Capsule().fill(
                            LinearGradient(
                                colors: [Color(hex: "a8c5a0"), Color(hex: "7eb8a4")],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                        .shadow(color: Color(hex: "a8c5a0").opacity(0.45), radius: 10, x: 0, y: 4)
                    )
                }
                .padding(.bottom, 8)
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 32)
            .background(
                RoundedRectangle(cornerRadius: 36)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.15), radius: 28, x: 0, y: -8)
            )
        }
        .ignoresSafeArea(edges: .bottom)
        .onAppear { withAnimation { appeared = true } }
        .onDisappear { player?.stop(); isPlaying = false }
    }

    func toggleVoice() {
        if isPlaying {
            player?.stop()
            isPlaying = false
        } else if let url = anchor.voiceURL {
            do {
                player = try AVAudioPlayer(contentsOf: url)
                player?.prepareToPlay()
                player?.play()
                isPlaying = true
            } catch {
                print("ReminderCardView playback error: \(error)")
            }
        }
    }
}

// ─────────────────────────────────────────────
// MARK: - Room Setup View
// ─────────────────────────────────────────────
struct RoomSetupView: View {
    var existingRoom: MemoryRoom? = nil
    let onSave: (MemoryRoom) -> Void

    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var onboardingStore: OnboardingStore

    @State private var room: MemoryRoom
    @State private var step: SetupStep = .photo
    @State private var capturedImage: UIImage?
    @State private var showCamera = false
    @State private var placingAnchor = false
    @State private var editingAnchor: MemoryAnchor? = nil

    enum SetupStep { case photo, annotate }

    init(existingRoom: MemoryRoom? = nil, onSave: @escaping (MemoryRoom) -> Void) {
        self.existingRoom = existingRoom
        self.onSave = onSave
        _room = State(initialValue: existingRoom ?? MemoryRoom())
        _step = State(initialValue: existingRoom?.imageFilename != nil ? .annotate : .photo)
    }

    var body: some View {
        ZStack {
            Color(hex: "f7f3ee").ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Button("Cancel") { dismiss() }
                        .font(.custom("Georgia", size: 16))
                        .foregroundColor(Color(hex: "9a8a7a"))

                    Spacer()

                    Text(existingRoom == nil ? "New Room" : "Edit Room")
                        .font(.custom("Snell Roundhand", size: 28))
                        .foregroundColor(Color(hex: "5c4a3a"))

                    Spacer()

                    if step == .annotate {
                        Button("Save") { saveRoom() }
                            .font(.custom("Georgia", size: 16)).fontWeight(.semibold)
                            .foregroundColor(Color(hex: "a8c5a0"))
                    } else {
                        Text("Save").font(.custom("Georgia", size: 16)).foregroundColor(.clear)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 56)
                .padding(.bottom, 24)

                switch step {
                case .photo:    photoStep
                case .annotate: annotateStep
                }
            }
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraPicker(image: $capturedImage)
                .ignoresSafeArea()
        }
        .onChange(of: capturedImage) { _, img in
            guard let img else { return }
            room.imageFilename = ImageFileStorage.replace(
                old: room.imageFilename, with: img, compressionQuality: 0.8
            )
            withAnimation { step = .annotate }
        }
        .sheet(item: $editingAnchor) { anchor in
            AnchorEditSheet(
                anchor: anchor,
                people: onboardingStore.people
            ) { updated in
                if let idx = room.anchors.firstIndex(where: { $0.id == updated.id }) {
                    room.anchors[idx] = updated
                }
            } onDelete: {
                room.anchors.removeAll { $0.id == anchor.id }
            }
        }
    }

    // ── Step 1: Photo ──
    var photoStep: some View {
        VStack(spacing: 32) {
            Text("Choose a photo of your surroundings")
                .font(.custom("Georgia", size: 18))
                .foregroundColor(Color(hex: "5c4a3a"))
                .multilineTextAlignment(.center)
                .lineSpacing(5)
                .padding(.horizontal, 24)

            VStack(alignment: .leading, spacing: 8) {
                Text("Room name")
                    .font(.custom("Georgia", size: 14))
                    .foregroundColor(Color(hex: "b0a090"))
                    .padding(.horizontal, 32)
                TextField("e.g. Kitchen, My Bedroom…", text: $room.roomName)
                    .font(.custom("Georgia", size: 17))
                    .foregroundColor(Color(hex: "333333"))
                    .padding(16)
                    .background(RoundedRectangle(cornerRadius: 14).fill(Color(hex: "ede8e0")))
                    .padding(.horizontal, 32)
            }

            VStack(spacing: 16) {
                Button { showCamera = true } label: {
                    HStack(spacing: 14) {
                        Image(systemName: "photo.on.rectangle").font(.system(size: 22))
                        Text("Choose a Photo")
                            .font(.custom("Georgia", size: 18)).fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity).padding(.vertical, 20)
                    .background(
                        RoundedRectangle(cornerRadius: 22)
                            .fill(LinearGradient(
                                colors: [Color(hex: "7ba7bc"), Color(hex: "a8c5a0")],
                                startPoint: .leading, endPoint: .trailing
                            ))
                            .shadow(color: Color(hex: "7ba7bc").opacity(0.4), radius: 12, x: 0, y: 6)
                    )
                }
                .padding(.horizontal, 32)

                Text("Your photo stays private on your device")
                    .font(.custom("Georgia", size: 13))
                    .foregroundColor(Color(hex: "b0a090"))
            }

            Spacer()
        }
        .padding(.top, 20)
    }

    // ── Step 2: Annotate ──
    var annotateStep: some View {
        GeometryReader { geo in
            let containerWidth = geo.size.width - 32
            let currentImage = capturedImage ?? room.image
            let imgHeight: CGFloat = {
                guard let img = currentImage else { return 260 }
                return containerWidth * (img.size.height / img.size.width)
            }()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 16) {
                    HStack(spacing: 10) {
                        Image(systemName: placingAnchor ? "mappin.circle.fill" : "hand.tap.fill")
                            .foregroundColor(Color(hex: "7ba7bc"))
                            .font(.system(size: 16))
                        Text(placingAnchor
                             ? "Tap the photo to drop a reminder pin"
                             : "Tap a pin to edit its reminder")
                            .font(.custom("Georgia", size: 14))
                            .foregroundColor(Color(hex: "5c4a3a"))
                        Spacer()
                    }
                    .padding(.horizontal, 16).padding(.vertical, 12)
                    .background(RoundedRectangle(cornerRadius: 14).fill(Color(hex: "e8f4f8")))
                    .padding(.horizontal, 16)

                    if let img = currentImage {
                        ZStack {
                            Image(uiImage: img)
                                .resizable()
                                .scaledToFill()
                                .frame(width: containerWidth, height: imgHeight)
                                .clipped()
                                .cornerRadius(18)
                                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                                .contentShape(Rectangle())
                                .onTapGesture { location in
                                    guard placingAnchor else { return }
                                    let newAnchor = MemoryAnchor(
                                        x: min(max(location.x / containerWidth, 0), 1),
                                        y: min(max(location.y / imgHeight, 0), 1)
                                    )
                                    room.anchors.append(newAnchor)
                                    placingAnchor = false
                                    editingAnchor = room.anchors.last
                                }

                            ForEach(room.anchors) { anchor in
                                SetupPinView()
                                    .position(
                                        x: anchor.x * containerWidth,
                                        y: anchor.y * imgHeight
                                    )
                                    .onTapGesture { editingAnchor = anchor }
                            }
                        }
                        .frame(width: containerWidth, height: imgHeight)
                        .padding(.horizontal, 16)
                    } else {
                        RoundedRectangle(cornerRadius: 18)
                            .fill(Color(hex: "e8e0d8"))
                            .frame(height: 260)
                            .padding(.horizontal, 16)
                    }

                    HStack(spacing: 12) {
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                placingAnchor.toggle()
                            }
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: placingAnchor ? "xmark.circle.fill" : "mappin.circle.fill")
                                    .font(.system(size: 16))
                                Text(placingAnchor ? "Cancel" : "Add Pin")
                                    .font(.custom("Georgia", size: 15)).fontWeight(.semibold)
                            }
                            .foregroundColor(placingAnchor ? Color(hex: "f07080") : .white)
                            .padding(.horizontal, 20).padding(.vertical, 13)
                            .background(Capsule().fill(
                                placingAnchor ? Color(hex: "f07080").opacity(0.12) : Color(hex: "7ba7bc")
                            ))
                        }

                        Button { showCamera = true } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "photo").font(.system(size: 14))
                                Text("Change").font(.custom("Georgia", size: 14))
                            }
                            .foregroundColor(Color(hex: "9a8a7a"))
                            .padding(.horizontal, 16).padding(.vertical, 13)
                            .background(Capsule().fill(Color(hex: "ede8e0")))
                        }

                        Spacer()

                        if !room.anchors.isEmpty {
                            HStack(spacing: 4) {
                                Image(systemName: "mappin.circle.fill")
                                    .font(.system(size: 13))
                                    .foregroundColor(Color(hex: "a8c5a0"))
                                Text("\(room.anchors.count)")
                                    .font(.custom("Georgia", size: 14)).fontWeight(.semibold)
                                    .foregroundColor(Color(hex: "5c4a3a"))
                            }
                            .padding(.horizontal, 12).padding(.vertical, 8)
                            .background(Capsule().fill(Color(hex: "f0f8f0")))
                        }
                    }
                    .padding(.horizontal, 16)

                    if !room.anchors.isEmpty {
                        VStack(spacing: 10) {
                            ForEach(room.anchors) { anchor in
                                HStack(spacing: 14) {
                                    Circle()
                                        .fill(Color(hex: "7ba7bc"))
                                        .frame(width: 10, height: 10)
                                    VStack(alignment: .leading, spacing: 3) {
                                        if !anchor.objectLabel.isEmpty {
                                            Text(anchor.objectLabel)
                                                .font(.custom("Georgia", size: 13))
                                                .foregroundColor(Color(hex: "b0a090"))
                                        }
                                        Text(anchor.reminderText.isEmpty
                                             ? "Tap to add reminder…"
                                             : anchor.reminderText)
                                            .font(.custom("Georgia", size: 15))
                                            .foregroundColor(anchor.reminderText.isEmpty
                                                             ? Color(hex: "c0b0a0")
                                                             : Color(hex: "3a2a1a"))
                                            .lineLimit(1)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 13))
                                        .foregroundColor(Color(hex: "c0b0a0"))
                                }
                                .padding(.horizontal, 16).padding(.vertical, 12)
                                .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.85)))
                                .onTapGesture { editingAnchor = anchor }
                            }
                        }
                        .padding(.horizontal, 16)
                    }

                    Spacer().frame(height: 50)
                }
            }
        }
    }

    func saveRoom() {
        onSave(room)
        dismiss()
    }
}

// ─────────────────────────────────────────────
// MARK: - Setup Pin View
// ─────────────────────────────────────────────
struct SetupPinView: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(Color(hex: "f07080").opacity(0.25))
                .frame(width: 34, height: 34)
            Circle()
                .fill(Color(hex: "f07080"))
                .frame(width: 18, height: 18)
                .shadow(color: .black.opacity(0.2), radius: 3, x: 0, y: 2)
        }
    }
}

// ─────────────────────────────────────────────
// MARK: - Anchor Edit Sheet
// ─────────────────────────────────────────────
struct AnchorEditSheet: View {
    @Environment(\.dismiss) var dismiss
    @State var anchor: MemoryAnchor
    let people: [PersonProfile]
    let onSave: (MemoryAnchor) -> Void
    let onDelete: () -> Void

    @State private var isRecording = false
    @State private var audioRecorder: AVAudioRecorder?
    @State private var recordingURL: URL?
    @State private var recordingDone = false
    @State private var audioPlayer: AVAudioPlayer?
    @State private var isPlaying = false

    var body: some View {
        ZStack {
            Color(hex: "f7f3ee").ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Button { dismiss() } label: {
                        Text("Cancel")
                            .font(.custom("Georgia", size: 16))
                            .foregroundColor(Color(hex: "9a8a7a"))
                    }
                    Spacer()
                    Text("Pin Reminder")
                        .font(.custom("Snell Roundhand", size: 26))
                        .foregroundColor(Color(hex: "5c4a3a"))
                    Spacer()
                    Button { saveAnchor(); dismiss() } label: {
                        Text("Done")
                            .font(.custom("Georgia", size: 16)).fontWeight(.semibold)
                            .foregroundColor(Color(hex: "a8c5a0"))
                    }
                }
                .padding(.horizontal, 24).padding(.top, 28).padding(.bottom, 24)

                ScrollView {
                    VStack(spacing: 22) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("What object is this? (optional)")
                                .font(.custom("Georgia", size: 14))
                                .foregroundColor(Color(hex: "b0a090"))
                            TextField("e.g. medicine cabinet, front door…", text: $anchor.objectLabel)
                                .font(.custom("Georgia", size: 16))
                                .foregroundColor(Color(hex: "333333"))
                                .padding(16)
                                .background(RoundedRectangle(cornerRadius: 14).fill(Color(hex: "ede8e0")))
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Reminder")
                                .font(.custom("Georgia", size: 14))
                                .foregroundColor(Color(hex: "b0a090"))
                            TextField("e.g. Take your morning medicine", text: $anchor.reminderText, axis: .vertical)
                                .font(.custom("Georgia", size: 17))
                                .foregroundColor(Color(hex: "333333"))
                                .lineLimit(2...4)
                                .padding(16)
                                .background(RoundedRectangle(cornerRadius: 14).fill(Color(hex: "ede8e0")))
                        }

                        if !people.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Link to a person (optional)")
                                    .font(.custom("Georgia", size: 14))
                                    .foregroundColor(Color(hex: "b0a090"))
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 10) {
                                        Button { anchor.linkedPersonName = nil } label: {
                                            Text("None")
                                                .font(.custom("Georgia", size: 14))
                                                .foregroundColor(anchor.linkedPersonName == nil ? .white : Color(hex: "9a8a7a"))
                                                .padding(.horizontal, 16).padding(.vertical, 10)
                                                .background(Capsule().fill(anchor.linkedPersonName == nil
                                                    ? Color(hex: "7ba7bc") : Color(hex: "ede8e0")))
                                        }
                                        ForEach(people) { person in
                                            Button { anchor.linkedPersonName = person.name } label: {
                                                HStack(spacing: 8) {
                                                    if let img = person.image {
                                                        Image(uiImage: img)
                                                            .resizable().scaledToFill()
                                                            .frame(width: 26, height: 26)
                                                            .clipShape(Circle())
                                                    }
                                                    Text(person.name)
                                                        .font(.custom("Georgia", size: 14))
                                                        .foregroundColor(anchor.linkedPersonName == person.name
                                                                         ? .white : Color(hex: "5c4a3a"))
                                                }
                                                .padding(.horizontal, 16).padding(.vertical, 10)
                                                .background(Capsule().fill(anchor.linkedPersonName == person.name
                                                    ? Color(hex: "7ba7bc") : Color(hex: "ede8e0")))
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            Text("Voice reminder (optional)")
                                .font(.custom("Georgia", size: 14))
                                .foregroundColor(Color(hex: "b0a090"))

                            HStack(spacing: 18) {
                                Button { isRecording ? stopRecording() : startRecording() } label: {
                                    ZStack {
                                        Circle()
                                            .fill(isRecording
                                                  ? Color(hex: "f07080").opacity(0.12)
                                                  : Color(hex: "7ba7bc").opacity(0.12))
                                            .frame(width: 68, height: 68)
                                            .scaleEffect(isRecording ? 1.15 : 1.0)
                                            .animation(
                                                isRecording
                                                ? .easeInOut(duration: 0.7).repeatForever(autoreverses: true)
                                                : .default,
                                                value: isRecording
                                            )
                                        Image(systemName: isRecording ? "stop.circle.fill" : "mic.circle.fill")
                                            .font(.system(size: 48))
                                            .foregroundColor(isRecording ? Color(hex: "f07080") : Color(hex: "7ba7bc"))
                                    }
                                }

                                VStack(alignment: .leading, spacing: 6) {
                                    Text(isRecording ? "Recording…"
                                         : (recordingDone || anchor.voiceFilename != nil) ? "✓ Voice recorded"
                                         : "Tap to record")
                                        .font(.custom("Georgia", size: 15))
                                        .foregroundColor((recordingDone || anchor.voiceFilename != nil)
                                                         ? Color(hex: "a8c5a0") : Color(hex: "9a8a7a"))

                                    if recordingDone {
                                        Button { togglePlayback() } label: {
                                            HStack(spacing: 6) {
                                                Image(systemName: isPlaying ? "stop.fill" : "play.fill")
                                                Text(isPlaying ? "Stop" : "Play back")
                                            }
                                            .font(.custom("Georgia", size: 13))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 16).padding(.vertical, 8)
                                            .background(Capsule().fill(Color(hex: "7ba7bc")))
                                        }
                                    }
                                }
                                Spacer()
                            }
                            .padding(16)
                            .background(RoundedRectangle(cornerRadius: 16).fill(Color(hex: "ede8e0")))
                        }

                        Button { onDelete(); dismiss() } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "trash")
                                Text("Remove this pin")
                            }
                            .font(.custom("Georgia", size: 15))
                            .foregroundColor(Color(hex: "f07080"))
                            .frame(maxWidth: .infinity).padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color(hex: "f07080").opacity(0.08))
                                    .overlay(RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color(hex: "f07080").opacity(0.3), lineWidth: 1))
                            )
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 50)
                }
            }
        }
    }

    func saveAnchor() {
        var saved = anchor
        if let url = recordingURL {
            VoiceFileStorage.delete(anchor.voiceFilename)
            saved.voiceFilename = VoiceFileStorage.save(from: url)
        }
        onSave(saved)
    }

    func startRecording() {
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            guard granted else {
                print("Mic permission denied")
                return
            }
            let url = FileManager.default.temporaryDirectory
                .appendingPathComponent("anchor_\(UUID().uuidString).m4a")
            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44100,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.medium.rawValue
            ]
            do {
                let recorder = try AVAudioRecorder(url: url, settings: settings)
                recorder.prepareToRecord()
                recorder.record()
                DispatchQueue.main.async {
                    self.audioRecorder = recorder
                    self.recordingURL = url
                    self.isRecording = true
                    self.recordingDone = false
                }
            } catch {
                print("Recording failed: \(error)")
            }
        }
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
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: url)
                audioPlayer?.prepareToPlay()
                audioPlayer?.play()
                isPlaying = true
            } catch {
                print("AnchorEditSheet playback error: \(error)")
            }
        }
    }
}