import SwiftUI

struct RegisterView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var onboardingStore: OnboardingStore
    @Environment(\.dismiss) var dismiss

    @State private var username = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var errorMessage = ""
    @State private var cardAppeared = false

    var body: some View {
        GeometryReader { geo in
            let cardWidth = min(540, max(320, geo.size.width - 32))
            let logoSize = max(110, min(150, cardWidth * 0.30))

            ZStack {
                Image("garden_background")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack {
                        Spacer(minLength: geo.safeAreaInsets.top + 24)

                        VStack(spacing: 22) {

                            // Logo + Title
                            VStack(spacing: 10) {
                                Image("logo")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: logoSize, height: logoSize)
                                    .padding(.top, 12)

                                Text("Create Account")
                                    .font(.custom("Snell Roundhand", size: 30))
                                    .foregroundColor(Color(hex: "7ba7bc"))
                            }

                            // Fields
                            VStack(spacing: 12) {
                                LiquidInputField(icon: "person", placeholder: "Username", text: $username, isSecure: false)
                                LiquidInputField(icon: "lock", placeholder: "Password", text: $password, isSecure: true)
                                LiquidInputField(icon: "lock.shield", placeholder: "Confirm Password", text: $confirmPassword, isSecure: true)
                            }

                            // Error
                            if !errorMessage.isEmpty {
                                Text(errorMessage)
                                    .font(.custom("Georgia", size: 13))
                                    .foregroundColor(Color(hex: "c97b84"))
                            }

                            // Buttons
                            VStack(spacing: 10) {
                                Button {
                                    attemptRegister()
                                } label: {
                                    Text("Sign Up")
                                        .font(.custom("Snell Roundhand", size: 20))
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 14)
                                        .background(
                                            RoundedRectangle(cornerRadius: 20)
                                                .fill(
                                                    LinearGradient(
                                                        colors: [Color(hex: "a8c5a0"), Color(hex: "7eb8a4")],
                                                        startPoint: .leading,
                                                        endPoint: .trailing
                                                    )
                                                )
                                                .shadow(color: Color(hex: "a8c5a0").opacity(0.5), radius: 8, x: 0, y: 4)
                                        )
                                }

                                Button {
                                    dismiss()
                                } label: {
                                    Text("Back to Login")
                                        .font(.custom("Georgia", size: 14))
                                        .foregroundColor(Color(hex: "7ba7bc"))
                                        .underline()
                                }
                            }
                            .padding(.bottom, 12)
                        }
                        .padding(.horizontal, 28)
                        .padding(.vertical, 30)
                        .frame(width: cardWidth)
                        .background(
                            RoundedRectangle(cornerRadius: 36)
                                .fill(Color.white.opacity(0.55))
                                .background(
                                    RoundedRectangle(cornerRadius: 36)
                                        .fill(.ultraThinMaterial)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 36)
                                        .stroke(Color.white.opacity(0.7), lineWidth: 1.5)
                                )
                                .shadow(color: .black.opacity(0.10), radius: 30, x: 0, y: 10)
                        )
                        .scaleEffect(cardAppeared ? 1 : 0.94)
                        .opacity(cardAppeared ? 1 : 0)
                        .onAppear {
                            withAnimation(.spring(response: 0.55, dampingFraction: 0.75)) {
                                cardAppeared = true
                            }
                        }

                        Spacer(minLength: geo.safeAreaInsets.bottom + 24)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }

    func attemptRegister() {
        guard !username.isEmpty, !password.isEmpty, !confirmPassword.isEmpty else {
            errorMessage = "Please fill in all fields"
            return
        }
        guard password == confirmPassword else {
            errorMessage = "Passwords do not match"
            return
        }
        guard password.count >= 6 else {
            errorMessage = "Password must be at least 6 characters"
            return
        }
        if !authManager.register(username: username, password: password) {
            errorMessage = "Username already taken"
            return
        }
        onboardingStore.resetOnboarding()
        authManager.requiresOnboarding = true
        dismiss()
    }
}