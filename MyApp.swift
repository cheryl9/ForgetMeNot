import SwiftUI

@main
struct MyApp: App {
    @StateObject var authManager = AuthManager()
    @StateObject var memoryStore = MemoryStore()
    @StateObject var onboardingStore = OnboardingStore()
    @StateObject var levelStore = LevelStore()
    @StateObject var memoryBoardStore = MemoryBoardStore()
    @StateObject var dropletStore = DropletStore()
    @StateObject private var shopStore = ShopStore()
    @StateObject var memoryWalkStore = MemoryWalkStore()  
    @StateObject private var musicPlayer = AmbientMusicPlayer()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authManager)
                .environmentObject(memoryStore)
                .environmentObject(onboardingStore)
                .environmentObject(levelStore)
                .environmentObject(memoryBoardStore)
                .environmentObject(dropletStore)
                .environmentObject(shopStore)
                .environmentObject(memoryWalkStore)  
                .environmentObject(musicPlayer)      
        }
    }
}