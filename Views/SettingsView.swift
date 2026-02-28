import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var memoryBoardStore: MemoryBoardStore
    @EnvironmentObject var shopStore: ShopStore
    @EnvironmentObject var musicPlayer: AmbientMusicPlayer
    @Environment(\.dismiss) var dismiss

    @State private var showMemoryBoard = false
    @State private var showGarden = false
    @State private var showLogoutConfirm = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Image("garden_background")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                Color.white.opacity(0.5).ignoresSafeArea()

                VStack(spacing: 0) {
                    // Nav bar
                    HStack {
                        Button(action: { dismiss() }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(Color(hex: "7ba7bc"))
                                .padding(10)
                                .background(Circle().fill(Color.white.opacity(0.9)))
                                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                        }
                        Spacer()
                        Text("Settings")
                            .font(.custom("Snell Roundhand", size: 40))
                            .foregroundColor(Color(hex: "5c4a3a"))
                        Spacer()
                        MusicToggleButton(musicPlayer: musicPlayer)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, geo.safeAreaInsets.top + 90)
                    .padding(.bottom, 32)

                    VStack(spacing: 16) {
                        // Logged in as card
                        HStack(spacing: 14) {
                            Circle()
                                .fill(Color(hex: "7ba7bc").opacity(0.2))
                                .frame(width: 48, height: 48)
                                .overlay(
                                    Text(authManager.currentUsername.prefix(1).uppercased())
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundColor(Color(hex: "7ba7bc"))
                                )
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Signed in as")
                                    .font(.custom("Georgia", size: 12))
                                    .foregroundColor(Color(hex: "aaaaaa"))
                                Text(authManager.currentUsername)
                                    .font(.custom("Georgia", size: 16))
                                    .fontWeight(.semibold)
                                    .foregroundColor(Color(hex: "444444"))
                            }
                            Spacer()
                        }
                        .padding(20)
                        .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.8)))

                        // Memory Board
                        SettingsRow(icon: "doc.plaintext.fill", label: "Memory Board", color: Color(hex: "f0c080")) {
                            showMemoryBoard = true
                        }

                        // My Garden
                        SettingsRow(icon: "leaf.fill", label: "My Garden", color: Color(hex: "7eb8a4")) {
                            showGarden = true
                        }

                        // Log Out
                        SettingsRow(icon: "rectangle.portrait.and.arrow.right", label: "Log Out", color: Color(hex: "f07080")) {
                            showLogoutConfirm = true
                        }
                    }
                    .frame(maxWidth: 500)
                    .padding(.horizontal, 24)

                    Spacer()
                }
            }
        }
        .ignoresSafeArea()
        .fullScreenCover(isPresented: $showMemoryBoard) {
            MemoryBoardView()
                .environmentObject(memoryBoardStore)
                .environmentObject(musicPlayer)
        }
        .fullScreenCover(isPresented: $showGarden) {
            MyGardenView()
                .environmentObject(shopStore)
                .environmentObject(musicPlayer)
        }
        .alert("Log Out", isPresented: $showLogoutConfirm) {
            Button("Log Out", role: .destructive) {
                authManager.logout()
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to log out? Your data will be saved for when you return.")
        }
    }
}

struct SettingsRow: View {
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(color)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(color.opacity(0.12)))
                Text(label)
                    .font(.custom("Georgia", size: 16))
                    .foregroundColor(Color(hex: "444444"))
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13))
                    .foregroundColor(Color(hex: "cccccc"))
            }
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.8)))
        }
    }
}