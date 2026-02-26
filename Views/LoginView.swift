import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var username = ""
    @State private var password = ""
    @State private var showRegister = false
    @State private var errorMessage = ""
    @State private var shake = false
    @State private var cardAppeared = false

    var body: some View {
        ZStack {
            Image("garden_background")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            VStack {
                Spacer()

                VStack(spacing: 22) {

                    // Logo 
                    Image("logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 150, height: 150)
                        .padding(.top, 12)

                    // Fields
                    VStack(spacing: 12) {
                        LiquidInputField(
                            icon: "person",
                            placeholder: "Username",
                            text: $username,
                            isSecure: false
                        )
                        LiquidInputField(
                            icon: "lock",
                            placeholder: "Password",
                            text: $password,
                            isSecure: true
                        )
                    }

                    // Error
                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .font(.custom("Georgia", size: 13))
                            .foregroundColor(Color(hex: "c97b84"))
                            .offset(x: shake ? -8 : 0)
                    }

                    // Login button
                    Button {
                        attemptLogin()
                    } label: {
                        Text("Login")
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

                    // Register link
                    HStack(spacing: 4) {
                        Text("Do not have an account?")
                            .font(.custom("Georgia", size: 13))
                            .foregroundColor(Color(hex: "888888"))
                        Button("Register") {
                            showRegister = true
                        }
                        .font(.custom("Georgia", size: 13))
                        .foregroundColor(Color(hex: "7ba7bc"))
                        .underline()
                        Text("here.")
                            .font(.custom("Georgia", size: 13))
                            .foregroundColor(Color(hex: "888888"))
                    }
                    .padding(.bottom, 12)
                }
                .padding(.horizontal, 36)
                .padding(.vertical, 32)
                .frame(width: 420) 
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

                Spacer()
            }
            .frame(maxWidth: .infinity)
        }
        .fullScreenCover(isPresented: $showRegister) {
            RegisterView()
        }
    }

    func attemptLogin() {
        if username.isEmpty || password.isEmpty {
            triggerError("Please fill in all fields")
            return
        }
        if !authManager.login(username: username, password: password) {
            triggerError("Invalid username or password")
        }
    }

    func triggerError(_ msg: String) {
        errorMessage = msg
        withAnimation(.default.repeatCount(3, autoreverses: true).speed(6)) {
            shake = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { shake = false }
    }
}