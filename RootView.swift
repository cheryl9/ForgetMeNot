import SwiftUI

struct RootView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var onboardingStore: OnboardingStore
    @EnvironmentObject var dropletStore: DropletStore
    @EnvironmentObject var memoryBoardStore: MemoryBoardStore
    @EnvironmentObject var levelStore: LevelStore
    @EnvironmentObject var shopStore: ShopStore
    @EnvironmentObject var memoryWalkStore: MemoryWalkStore
    
    var body: some View {
        Group {
            if authManager.isLoggedIn {
                if authManager.requiresOnboarding {
                    OnboardingView()
                } else {
                    HomeView()
                }
            } else {
                LoginView()
            }
        }
        // When user logs in normally, load their data
        .onChange(of: authManager.isLoggedIn) {
            if authManager.isLoggedIn {
                let username = authManager.currentUsername
                // Skip if demo — loginAsDemo() already loaded stores
                if username != "demo" {
                    onboardingStore.load(for: username)
                    dropletStore.load(for: username)
                    memoryBoardStore.load(for: username)
                    levelStore.load(for: username)
                    shopStore.load(for: username)
                    memoryWalkStore.load(for: username)
                }
            }
        }
    }
}
