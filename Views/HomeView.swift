import SwiftUI

enum HomeSheet: Identifiable {
    case level(Int), setup, memoryBoard, shop, memoryWalk
    var id: String {
        switch self {
        case .level(let l):  return "level_\(l)"
        case .setup:         return "setup"
        case .memoryBoard:   return "memoryBoard"
        case .shop:          return "shop"
        case .memoryWalk:    return "memoryWalk"
        }
    }
}

struct HomeView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var memoryStore: MemoryStore
    @EnvironmentObject var levelStore: LevelStore
    @EnvironmentObject var memoryBoardStore: MemoryBoardStore
    @EnvironmentObject var dropletStore: DropletStore
    @EnvironmentObject var onboardingStore: OnboardingStore
    @EnvironmentObject var shopStore: ShopStore
    @EnvironmentObject var memoryWalkStore: MemoryWalkStore
    // Injected from app root so music survives sheet transitions
    @EnvironmentObject var musicPlayer: AmbientMusicPlayer

    @State private var activeSheet: HomeSheet? = nil
    @State private var appeared = false

    let rockPositions: [(x: CGFloat, y: CGFloat)] = [
        (0.47, 0.93),
        (0.42, 0.85),
        (0.46, 0.78),
        (0.50, 0.72),
        (0.44, 0.65),
        (0.38, 0.60),
        (0.43, 0.52),
        (0.48, 0.45),
    ]

    var body: some View {
        NavigationView {
            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height
                let isIPad = w >= 768
                let contentWidth: CGFloat = isIPad ? min(w * 0.82, 760) : w
                let xOffset = (w - contentWidth) / 2

                ZStack(alignment: .topLeading) {
                    Image("rock_background")
                        .resizable()
                        .scaledToFill()
                        .frame(width: w, height: h)
                        .clipped()
                        .ignoresSafeArea()

                    // Rock level buttons
                    ForEach(0..<rockPositions.count, id: \.self) { i in
                        let pos = rockPositions[i]
                        let isUnlocked = levelStore.isUnlocked(i + 1)
                        RockLevelButton(level: i + 1, isUnlocked: isUnlocked) {
                            activeSheet = .level(i + 1)
                        }
                        .position(x: xOffset + contentWidth * pos.x, y: h * pos.y)
                        .scaleEffect(appeared ? 1 : 0.4)
                        .opacity(appeared ? 1 : 0)
                        .animation(
                            .spring(response: 0.45, dampingFraction: 0.65).delay(Double(i) * 0.06),
                            value: appeared
                        )
                    }

                    // ── Left side buttons ──
                    VStack(alignment: .leading, spacing: geo.size.height < 500 ? 8 : 12) {
                        SideCircleButton(icon: "basket.fill", color: Color(hex: "9BD7D1")) {
                            activeSheet = .shop
                        }
                        SideCircleButton(icon: "gearshape.fill", color: Color(hex: "B4C5FD")) {
                            activeSheet = .setup
                        }
                        SideCircleButton(icon: "doc.plaintext.fill", color: Color(hex: "FDDDB4")) {
                            activeSheet = .memoryBoard
                        }
                        SideCircleButton(icon: "camera.fill", color: Color(hex: "F4A8B8")) {
                            activeSheet = .memoryWalk
                        }
                    }
                    .padding(.leading, xOffset + 16)
                    .padding(.top, geo.safeAreaInsets.top + (geo.size.height < 500 ? 40 : 70))

                    // ── Top-right water drop pill ──
                    VStack {
                        HStack {
                            Spacer()
                            HStack(spacing: 6) {
                                Image(systemName: "drop.fill")
                                    .foregroundColor(.white)
                                    .font(.system(size: 14, weight: .bold))
                                Text("\(dropletStore.totalDroplets)")
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 9)
                            .background(
                                Capsule()
                                    .fill(Color(hex: "FFBEBE"))
                                    .shadow(color: Color(hex: "f07080").opacity(0.4), radius: 8, x: 0, y: 3)
                            )
                            .padding(.trailing, xOffset + 16)
                        }
                        .padding(.top, geo.safeAreaInsets.top + (geo.size.height < 500 ? 80 : 120))
                        Spacer()
                    }

                    // ── Bottom-right music button ──
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            MusicToggleButton(musicPlayer: musicPlayer)
                                .padding(.trailing, xOffset + 20)
                                .padding(.bottom, geo.safeAreaInsets.bottom + 24)
                        }
                    }
                }
            }
            .ignoresSafeArea()
            .onAppear { withAnimation { appeared = true } }
            .fullScreenCover(item: $activeSheet) { sheet in
                switch sheet {
                case .level(let level):
                    LevelEntryView(
                        level: level,
                        onExitToHome: { activeSheet = nil }
                    )
                    .environmentObject(memoryStore)
                    .environmentObject(onboardingStore)
                    .environmentObject(levelStore)
                    .environmentObject(memoryBoardStore)
                    .environmentObject(dropletStore)

                case .shop:
                    ShopView()
                        .environmentObject(shopStore)
                        .environmentObject(dropletStore)

                case .setup:
                    SettingsView()
                        .environmentObject(authManager)
                        .environmentObject(memoryBoardStore)
                        .environmentObject(shopStore)

                case .memoryBoard:
                    MemoryBoardView()
                        .environmentObject(memoryBoardStore)

                case .memoryWalk:
                    NavigationView {
                        MemoryWalkView()
                            .environmentObject(memoryWalkStore)
                            .environmentObject(onboardingStore)
                    }
                    .navigationViewStyle(.stack)
                }
            }
        }
        .navigationViewStyle(.stack)
    }
}

// MARK: - Rock Level Button
struct RockLevelButton: View {
    let level: Int
    let isUnlocked: Bool
    let action: () -> Void
    @State private var bouncing = false

    var body: some View {
        Button(action: {
            guard isUnlocked else { return }
            triggerBounce()
            action()
        }) {
            ZStack {
                Ellipse()
                    .fill(
                        LinearGradient(
                            colors: isUnlocked
                                ? [Color(hex: "c8b89a"), Color(hex: "a0896e")]
                                : [Color(hex: "aaaaaa").opacity(0.75), Color(hex: "777777").opacity(0.75)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(Ellipse().stroke(Color.white.opacity(0.5), lineWidth: 1.5))
                    .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 3)
                    .frame(width: 62, height: 38)

                HStack(spacing: 3) {
                    if !isUnlocked {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.white.opacity(0.9))
                    }
                    Text("\(level)")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.4), radius: 1, x: 0, y: 1)
                }
            }
        }
        .scaleEffect(bouncing ? CGSize(width: 0.82, height: 0.88) : CGSize(width: 1, height: 1))
        .rotationEffect(bouncing ? .degrees(-5) : .degrees(0))
        .animation(.spring(response: 0.25, dampingFraction: 0.35), value: bouncing)
        .disabled(!isUnlocked)
    }

    func triggerBounce() {
        bouncing = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { bouncing = false }
    }
}

// MARK: - Side Circle Button
struct SideCircleButton: View {
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 50, height: 50)
                .background(Circle().fill(color))
                .shadow(color: color.opacity(0.45), radius: 6, x: 0, y: 3)
        }
    }
}