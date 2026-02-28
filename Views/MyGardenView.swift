import SwiftUI

struct MyGardenView: View {
    @EnvironmentObject var shopStore: ShopStore
    @EnvironmentObject var musicPlayer: AmbientMusicPlayer
    @Environment(\.dismiss) var dismiss
    
    var purchasedItems: [ShopItem] {
        ShopItem.catalog.filter { shopStore.hasPurchased($0) }
    }
    
    var body: some View {
        GeometryReader { geo in
            let horizontalPadding: CGFloat = 24
            let availableWidth = max(240, geo.size.width - (horizontalPadding * 2))
            let columnCount = min(5, max(2, Int(availableWidth / 135)))
            let columns = Array(repeating: GridItem(.flexible(), spacing: 20), count: columnCount)
            
            ZStack {
                // Background
                Image("rock_background")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
                    .ignoresSafeArea()
                
                Color.white.opacity(0.35)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Top bar
                    HStack {
                        Button(action: { dismiss() }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Color(hex: "7a6a5a"))
                                .padding(10)
                                .background(Circle().fill(Color.white.opacity(0.85)))
                                .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
                        }
                        Spacer()
                        Text("My Garden")
                            .font(.custom("Snell Roundhand", size: 40))
                            .fontWeight(.semibold)
                            .foregroundColor(Color(hex: "5c4a3a"))
                        Spacer()
                        MusicToggleButton(musicPlayer: musicPlayer)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, max(geo.safeAreaInsets.top, 50) + 32)
                    
                    Text("\(purchasedItems.count) of \(ShopItem.catalog.count) plants collected")
                        .font(.system(size: 13, design: .rounded))
                        .foregroundColor(Color(hex: "9a8a7a"))
                        .padding(.top, 6)
                        .padding(.bottom, 20)
                    
                    if purchasedItems.isEmpty {
                        Spacer()
                        VStack(spacing: 16) {
                            Text("🪴")
                                .font(.system(size: 64))
                            Text("Your garden is empty")
                                .font(.custom("Georgia", size: 18))
                                .foregroundColor(Color(hex: "7a6a5a"))
                            Text("Visit the shop to collect plants!")
                                .font(.system(size: 14))
                                .foregroundColor(Color(hex: "9a8a7a"))
                        }
                        .padding(32)
                        .background(
                            RoundedRectangle(cornerRadius: 24)
                                .fill(Color.white.opacity(0.75))
                                .shadow(color: .black.opacity(0.07), radius: 12, x: 0, y: 4)
                        )
                        .padding(.horizontal, 40)
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVGrid(columns: columns, spacing: 20) {
                                ForEach(purchasedItems) { item in
                                    GardenPlantCard(item: item)
                                }
                                ForEach(ShopItem.catalog.filter { !shopStore.hasPurchased($0) }) { item in
                                    LockedPlantSlot()
                                }
                            }
                            .padding(.horizontal, 24)
                            .padding(.bottom, geo.safeAreaInsets.bottom + 24)
                        }
                    }
                }
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Garden Plant Card (owned)
struct GardenPlantCard: View {
    let item: ShopItem
    @State private var wiggle = false
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "e8f5e8"), Color(hex: "c8e6c8")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 90, height: 90)
                    .shadow(color: Color(hex: "a8c5a0").opacity(0.4), radius: 8, x: 0, y: 3)
                
                Image(item.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 65, height: 65)
                    .rotationEffect(.degrees(wiggle ? -4 : 4))
                    .animation(
                        .easeInOut(duration: 1.8).repeatForever(autoreverses: true),
                        value: wiggle
                    )
            }
            
            Text(item.name)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(Color(hex: "5c4a3a"))
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white.opacity(0.72))
                .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 3)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color(hex: "a8c5a0").opacity(0.5), lineWidth: 1.5)
        )
        .onAppear { wiggle = true }
    }
}

// MARK: - Locked Slot (not yet purchased)
struct LockedPlantSlot: View {
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(Color(hex: "eeeeee").opacity(0.6))
                    .frame(width: 90, height: 90)
                
                Image(systemName: "lock.fill")
                    .font(.system(size: 24))
                    .foregroundColor(Color(hex: "cccccc"))
            }
            
            Text("???")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(Color(hex: "cccccc"))
        }
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white.opacity(0.4))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color(hex: "dddddd").opacity(0.6), lineWidth: 1.5)
        )
    }
}
