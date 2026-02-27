import Foundation

class ShopStore: ObservableObject {
    @Published var purchasedItemIDs: Set<String> = []
    
    private var userKey: String = "guest"

    func hasPurchased(_ item: ShopItem) -> Bool {
        purchasedItemIDs.contains(item.id)
    }

    @discardableResult
    func purchase(_ item: ShopItem, dropletStore: DropletStore) -> Bool {
        guard !hasPurchased(item) else { return true }
        guard dropletStore.totalDroplets >= item.cost else { return false }
        dropletStore.spend(item.cost)
        purchasedItemIDs.insert(item.id)
        save()
        return true
    }

    func load(for username: String) {
        userKey = username.lowercased().trimmingCharacters(in: .whitespaces)
        let array = UserDefaults.standard.stringArray(forKey: "shop_purchased_\(userKey)") ?? []
        purchasedItemIDs = Set(array)
    }

    private func save() {
        let array = Array(purchasedItemIDs)
        UserDefaults.standard.set(array, forKey: "shop_purchased_\(userKey)")
    }
}