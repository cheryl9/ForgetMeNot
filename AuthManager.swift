import SwiftUI

class AuthManager: ObservableObject {
    @Published var isLoggedIn = false
    @Published var currentUsername = ""
    @Published var requiresOnboarding = false

    // Load saved users from UserDefaults on init
    private var users: [String: String] {
        get {
            UserDefaults.standard.dictionary(forKey: "registered_users") as? [String: String] ?? [:]
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "registered_users")
        }
    }

    func login(username: String, password: String) -> Bool {
        let trimmed = username.trimmingCharacters(in: .whitespaces)
        guard let stored = users[trimmed.lowercased()], stored == password else {
            return false
        }
        currentUsername = trimmed
        isLoggedIn = true
        requiresOnboarding = false
        return true
    }

    func register(username: String, password: String) -> Bool {
        let trimmed = username.trimmingCharacters(in: .whitespaces).lowercased()
        // Duplicate check
        guard users[trimmed] == nil else { return false }
        // Save to persistent storage
        var current = users
        current[trimmed] = password
        users = current
        currentUsername = username.trimmingCharacters(in: .whitespaces)
        isLoggedIn = true
        requiresOnboarding = true
        return true
    }

    func logout() {
        isLoggedIn = false
        currentUsername = ""
        requiresOnboarding = false
    }
}