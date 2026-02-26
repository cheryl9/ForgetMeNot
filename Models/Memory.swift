import SwiftUI
import AVFoundation

// MARK: - Memory Model
struct Memory: Identifiable, Codable {
    var id = UUID()
    // FILE-BASED: filenames only — no raw Data blobs
    var imageFilename: String? = nil
    var voiceFilename: String? = nil
    var type: MemoryType

    var personName: String = ""
    var location: String = ""
    var activity: String = ""
    var dateTaken: String = ""
    var distractors: [String] = []

    // Convenience accessors — load from disk on demand
    var image: UIImage? { ImageFileStorage.load(imageFilename) }
    var voiceURL: URL? { VoiceFileStorage.url(for: voiceFilename) }

    enum MemoryType: String, Codable {
        case photo, voice
    }
}

// MARK: - Memory Store (persistence)
class MemoryStore: ObservableObject {
    @Published var memories: [Memory] = []
    private let key = "saved_memories"

    init() { load() }

    func add(_ memory: Memory) {
        memories.append(memory)
        save()
    }

    func delete(_ memory: Memory) {
        // Clean up files from disk before removing record
        ImageFileStorage.delete(memory.imageFilename)
        VoiceFileStorage.delete(memory.voiceFilename)
        memories.removeAll { $0.id == memory.id }
        save()
    }

    func update(_ memory: Memory) {
        if let idx = memories.firstIndex(where: { $0.id == memory.id }) {
            memories[idx] = memory
            save()
        }
    }

    private func save() {
        // Only tiny filenames in UserDefaults — no image/audio blobs
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

// MARK: - Voice File Storage
enum VoiceFileStorage {
    private static var documentsURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    /// Copy a temporary recording URL to permanent Documents storage. Returns the new filename.
    static func save(from url: URL) -> String? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        let filename = UUID().uuidString + ".m4a"
        let dest = documentsURL.appendingPathComponent(filename)
        do {
            try data.write(to: dest, options: .atomic)
            return filename
        } catch {
            print("VoiceFileStorage: write failed: \(error)")
            return nil
        }
    }

    /// Return the full URL for a stored voice filename.
    static func url(for filename: String?) -> URL? {
        guard let filename, !filename.isEmpty else { return nil }
        return documentsURL.appendingPathComponent(filename)
    }

    /// Delete the file for a given filename. Safe to call with nil.
    static func delete(_ filename: String?) {
        guard let filename, !filename.isEmpty else { return }
        try? FileManager.default.removeItem(at: documentsURL.appendingPathComponent(filename))
    }
}