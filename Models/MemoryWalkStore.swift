import SwiftUI
import AVFoundation

// MARK: - Memory Anchor
// Represents one tappable pin on a room photo.
// x/y are stored as 0.0–1.0 fractions of the image size
// so pins survive layout changes and different screen sizes.
struct MemoryAnchor: Identifiable, Codable {
    var id = UUID()
    var x: CGFloat                      // 0.0 – 1.0 relative to image width
    var y: CGFloat                      // 0.0 – 1.0 relative to image height
    var reminderText: String = ""
    var voiceFilename: String? = nil
    var linkedPersonName: String? = nil // ties to OnboardingStore person
    var emoji: String = "🌸"            // visual pin icon
    var objectLabel: String = ""        // e.g. "medicine cabinet"

    var voiceURL: URL? { VoiceFileStorage.url(for: voiceFilename) }
}

// MARK: - Memory Room
// One photographed room with its anchors.
struct MemoryRoom: Identifiable, Codable {
    var id = UUID()
    var roomName: String = "My Room"
    var imageFilename: String? = nil
    var anchors: [MemoryAnchor] = []
    var dateCreated: Date = Date()

    var image: UIImage? { ImageFileStorage.load(imageFilename) }
}

// MARK: - Memory Walk Store
class MemoryWalkStore: ObservableObject {
    @Published var rooms: [MemoryRoom] = []
    private var userKey: String = "guest"

    init() {}

    func load(for username: String) {
        userKey = username.lowercased().trimmingCharacters(in: .whitespaces)
        if let data = UserDefaults.standard.data(forKey: "memoryWalk_\(userKey)"),
           let decoded = try? JSONDecoder().decode([MemoryRoom].self, from: data) {
            rooms = decoded
        } else { rooms = [] }
    }

    func addRoom(_ room: MemoryRoom) {
        rooms.append(room)
        save()
    }

    func updateRoom(_ room: MemoryRoom) {
        if let idx = rooms.firstIndex(where: { $0.id == room.id }) {
            rooms[idx] = room
            save()
        }
    }

    func deleteRoom(_ room: MemoryRoom) {
        ImageFileStorage.delete(room.imageFilename)
        for anchor in room.anchors {
            VoiceFileStorage.delete(anchor.voiceFilename)
        }
        rooms.removeAll { $0.id == room.id }
        save()
    }

    private func save() {
        if let data = try? JSONEncoder().encode(rooms) {
            UserDefaults.standard.set(data, forKey: "memoryWalk_\(userKey)")
        }
    }
}
