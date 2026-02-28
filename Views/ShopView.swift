import SwiftUI

struct ShopView: View {
    @EnvironmentObject var shopStore: ShopStore
    @EnvironmentObject var dropletStore: DropletStore
    @EnvironmentObject var musicPlayer: AmbientMusicPlayer
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedItem: ShopItem? = nil
    @State private var showInsufficientFunds = false
    
    var body: some View {
        GeometryReader { geo in
            let availableWidth = max(240, geo.size.width - 30)
            let columnCount = min(6, max(2, Int(availableWidth / 150)))
            let columns = Array(repeating: GridItem(.flexible(), spacing: 16), count: columnCount)
            
            ZStack {
                // Background
                Image("shop_background")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
                    .ignoresSafeArea()
                
                Color(hex: "f5f0e8").opacity(0.3)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Top bar
                    ZStack {
                        HStack {
                            Button(action: { dismiss() }) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(Color(hex: "7a6a5a"))
                                    .padding(10)
                                    .background(Circle().fill(Color.white.opacity(0.8)))
                            }
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
                            Spacer()
                            MusicToggleButton(musicPlayer: musicPlayer)
                        }
                        
                        Text("My Garden")
                            .font(.custom("Snell Roundhand", size: 40))
                            .fontWeight(.semibold)
                            .foregroundColor(Color(hex: "5c4a3a"))
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, max(geo.safeAreaInsets.top, 50) + 32)
                    .padding(.bottom, 20)
                    
                    // Grid
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(ShopItem.catalog) { item in
                                ShopItemCard(item: item, isPurchased: shopStore.hasPurchased(item)) {
                                    selectedItem = item
                                }
                            }
                        }
                        .padding(15)
                        .padding(.bottom, geo.safeAreaInsets.bottom + 20)
                    }
                }
            }
        }
        .ignoresSafeArea()
        .sheet(item: $selectedItem) { item in
            PurchaseConfirmSheet(
                item: item,
                isPurchased: shopStore.hasPurchased(item),
                canAfford: dropletStore.totalDroplets >= item.cost,
                onBuy: {
                    let success = shopStore.purchase(item, dropletStore: dropletStore)
                    if !success { showInsufficientFunds = true }
                    selectedItem = nil
                },
                onBack: { selectedItem = nil }
            )
            .presentationDetents([.fraction(0.5)])
            .presentationCornerRadius(28)
        }
        .alert("Not enough droplets 💧", isPresented: $showInsufficientFunds) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Keep playing quizzes to earn more droplets!")
        }
    }
}

// MARK: - Shop Item Card
struct ShopItemCard: View {
    let item: ShopItem
    let isPurchased: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.6))
                        .frame(width: 110, height: 110)
                    
                    Image(item.imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 85, height: 85)
                }
                
                Text(item.name)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(Color(hex: "5c4a3a"))
                
                if isPurchased {
                    Label("Owned", systemImage: "checkmark.circle.fill")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color(hex: "7bc67a"))
                } else {
                    HStack(spacing: 4) {
                        Image(systemName: "drop.fill")
                            .font(.system(size: 12))
                            .foregroundColor(Color(hex: "FFBEBE"))
                        Text("\(item.cost)")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(Color(hex: "c47e7e"))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(Color(hex: "fff0f0")))
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .frame(height: 200)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(isPurchased ? 0.5 : 0.78))
                    .shadow(color: .black.opacity(0.07), radius: 8, x: 0, y: 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isPurchased ? Color(hex: "7bc67a").opacity(0.4) : Color.white.opacity(0.5), lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Purchase Confirmation Sheet
struct PurchaseConfirmSheet: View {
    let item: ShopItem
    let isPurchased: Bool
    let canAfford: Bool
    let onBuy: () -> Void
    let onBack: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Image(systemName: "circle.dotted")
                    .font(.system(size: 120))
                    .foregroundColor(Color(hex: "c8dfc8").opacity(0.6))
                
                Image(item.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 90, height: 90)
            }
            .padding(.top, 18)
            
            Text(item.name)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(Color(hex: "5c4a3a"))
            
            if isPurchased {
                Label("Already owned!", systemImage: "checkmark.circle.fill")
                    .foregroundColor(Color(hex: "7bc67a"))
                    .font(.system(size: 16, weight: .semibold))
            }
            
            HStack(spacing: 16) {
                Button(action: onBack) {
                    Text("< Back")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(Color(hex: "7a6a5a"))
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Capsule().fill(Color(hex: "e8ddd0")))
                }
                
                if !isPurchased {
                    Button(action: onBuy) {
                        HStack(spacing: 6) {
                            Text("\(item.cost)")
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                            Image(systemName: "drop.fill")
                                .font(.system(size: 13))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(
                            Capsule()
                                .fill(canAfford ? Color(hex: "FFBEBE") : Color.gray.opacity(0.4))
                        )
                    }
                    .disabled(!canAfford)
                }
            }
            .padding(.bottom, 32)
        }
        .frame(maxWidth: .infinity)
        .background(Color(hex: "fdf8f2"))
    }
}
