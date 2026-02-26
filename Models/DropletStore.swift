import SwiftUI

// MARK: - Droplet Store (per-user water droplet count)
class DropletStore: ObservableObject {
    @Published var totalDroplets: Int = 0
    private var userKey: String = "guest"

    init() {}

    func load(for username: String) {
        userKey = username.lowercased().trimmingCharacters(in: .whitespaces)
        totalDroplets = UserDefaults.standard.integer(forKey: "droplets_\(userKey)")
    }

    func add(_ count: Int) {
        totalDroplets += count
        UserDefaults.standard.set(totalDroplets, forKey: "droplets_\(userKey)")
    }

    func reset() {
        totalDroplets = 0
    }
}