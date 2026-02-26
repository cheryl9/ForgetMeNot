import SwiftUI

class LevelStore: ObservableObject {
    @Published var unlockedLevels: Set<Int> = [1]
    private var userKey: String = "guest"

    init() {}

    func load(for username: String) {
        userKey = username.lowercased().trimmingCharacters(in: .whitespaces)
        let arr = UserDefaults.standard.array(forKey: "unlockedLevels_\(userKey)") as? [Int] ?? [1]
        unlockedLevels = Set(arr.isEmpty ? [1] : arr)
    }

    func isUnlocked(_ level: Int) -> Bool { unlockedLevels.contains(level) }

    func unlock(_ level: Int) {
        unlockedLevels.insert(level)
        persist()
    }

    func completeLevel(_ level: Int) { unlock(level + 1) }

    private func persist() {
        UserDefaults.standard.set(Array(unlockedLevels), forKey: "unlockedLevels_\(userKey)")
    }
}