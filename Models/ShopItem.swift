import Foundation

struct ShopItem: Identifiable {
    let id: String
    let name: String
    let cost: Int
    let imageName: String  // Asset catalog image name — add your PNGs to Assets.xcassets with these exact names

    static let catalog: [ShopItem] = [
        ShopItem(id: "fuschia",       name: "Fuschia",       cost: 20, imageName: "plant_fuschia"),
        ShopItem(id: "lavender",      name: "Lavender",      cost: 10, imageName: "plant_lavender"),
        ShopItem(id: "daisy",         name: "Daisy",         cost: 30, imageName: "plant_daisy"),
        ShopItem(id: "rose",          name: "Rose",          cost: 60, imageName: "plant_rose"),
        ShopItem(id: "sunflower",     name: "Sunflower",     cost: 45, imageName: "plant_sunflower"),
        ShopItem(id: "tulip",         name: "Tulip",         cost: 35, imageName: "plant_tulip"),
        ShopItem(id: "hydrangea",     name: "Hydrangea",     cost: 35, imageName: "plant_hydrangea"),
        ShopItem(id: "lily",          name: "Lily",          cost: 50, imageName: "plant_lily"),
        ShopItem(id: "peony",         name: "Peony",         cost: 65, imageName: "plant_peony"),
        ShopItem(id: "forget_me_not", name: "Forget Me Not", cost: 80, imageName: "plant_forget_me_not"),
    ]
}