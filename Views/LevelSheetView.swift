import SwiftUI

struct LevelEntryView: View {
    let level: Int
    var onExitToHome: (() -> Void)? = nil   // FIX: accept callback from HomeView

    @EnvironmentObject var memoryStore: MemoryStore
    @EnvironmentObject var onboardingStore: OnboardingStore
    @EnvironmentObject var levelStore: LevelStore
    @EnvironmentObject var memoryBoardStore: MemoryBoardStore
    @EnvironmentObject var dropletStore: DropletStore
    @Environment(\.dismiss) var dismiss
    @State private var goToQuiz = false

    var body: some View {
        ZStack {
            Image("garden_background")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
            Color.white.opacity(0.5).ignoresSafeArea()
            VStack(spacing: 32) {

                Text("Level \(level)")
                    .font(.custom("Snell Roundhand", size: 32))
                    .foregroundColor(Color(hex: "7ba7bc"))

                Button {
                    goToQuiz = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 16))
                        Text("Play")
                            .font(.custom("Georgia", size: 18))
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(width: 200)
                    .padding(.vertical, 16)
                    .background(
                        Capsule()
                            .fill(Color(hex: "f07080"))
                            .overlay(Capsule().stroke(Color.white.opacity(0.4), lineWidth: 1))
                            .shadow(color: Color(hex: "f07080").opacity(0.4), radius: 10, x: 0, y: 5)
                    )
                }

                Button {
                    dismiss()
                } label: {
                    Text("Not now")
                        .font(.custom("Georgia", size: 15))
                        .foregroundColor(Color(hex: "aaaaaa"))
                }
            }
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 36)
                    .fill(Color.white.opacity(0.7))
                    .background(RoundedRectangle(cornerRadius: 36).fill(.ultraThinMaterial))
                    .overlay(RoundedRectangle(cornerRadius: 36).stroke(Color.white.opacity(0.6), lineWidth: 1.5))
                    .shadow(color: .black.opacity(0.1), radius: 24, x: 0, y: 10)
            )
            .padding(.horizontal, 40)
        }
        .fullScreenCover(isPresented: $goToQuiz) {
            // FIX: pass onExitToHome through so "Back to Garden" dismisses all the way to HomeView
            QuizView(level: level, onExitToHome: onExitToHome ?? { dismiss() })
                .environmentObject(memoryStore)
                .environmentObject(onboardingStore)
                .environmentObject(levelStore)
                .environmentObject(memoryBoardStore)
                .environmentObject(dropletStore)
        }
    }
}