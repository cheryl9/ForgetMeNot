import SwiftUI
import AVFoundation

// MARK: - Memory Model (for MemoryStore / legacy quiz use)
struct Memory: Identifiable, Codable {
    var id = UUID()
    var imageFilename: String? = nil
    var voiceFilename: String? = nil
    var type: MemoryType

    var personName: String = ""
    var location: String = ""
    var activity: String = ""
    var dateTaken: String = ""
    var distractors: [String] = []

    var image: UIImage? { ImageFileStorage.load(imageFilename) }
    var voiceURL: URL? { VoiceFileStorage.url(for: voiceFilename) }

    enum MemoryType: String, Codable {
        case photo, voice
    }
}

// MARK: - Memory Store
class MemoryStore: ObservableObject {
    @Published var memories: [Memory] = []
    private let key = "saved_memories"

    init() { load() }

    func add(_ memory: Memory) { memories.append(memory); save() }

    func delete(_ memory: Memory) {
        ImageFileStorage.delete(memory.imageFilename)
        VoiceFileStorage.delete(memory.voiceFilename)
        memories.removeAll { $0.id == memory.id }
        save()
    }

    func update(_ memory: Memory) {
        if let idx = memories.firstIndex(where: { $0.id == memory.id }) {
            memories[idx] = memory; save()
        }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(memories) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    private func load() {
        if let data = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode([Memory].self, from: data) {
            memories = decoded
        }
    }
}