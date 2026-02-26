import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var memoryStore: MemoryStore
    @Environment(\.dismiss) var dismiss
    @State private var showCaregiverSetup = false
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
                            .font(.custom("Snell Roundhand", size: 28))
                            .foregroundColor(Color(hex: "7ba7bc"))
                        Spacer()
                        // Balance
                        Color.clear.frame(width: 40, height: 40)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, geo.safeAreaInsets.top + 16)
                    .padding(.bottom, 24)

                    VStack(spacing: 16) {
                        // Logged in as
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
                        .padding(16)
                        .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.8)))

                        // Add Memory button → goes to CaregiverSetupView
                        SettingsRow(icon: "photo.on.rectangle.angled", label: "Manage Memories", color: Color(hex: "a8c5a0")) {
                            showCaregiverSetup = true
                        }

                        // Logout
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
        .fullScreenCover(isPresented: $showCaregiverSetup) {
            CaregiverSetupView()
                .environmentObject(memoryStore)
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