
import Foundation

struct DataManager {
    static let shared = DataManager()
    private let userDefaults = UserDefaults(suiteName: "group.com.example.SixEats")

    private let lastEatDateKey = "lastEatDate"
    private let checkedItemsKey = "checkedItems"

    func save(lastEatDate: Date) {
        userDefaults?.set(lastEatDate, forKey: lastEatDateKey)
    }

    func loadLastEatDate() -> Date? {
        return userDefaults?.object(forKey: lastEatDateKey) as? Date
    }

    func save(checkedItems: [String]) {
        userDefaults?.set(checkedItems, forKey: checkedItemsKey)
    }

    func loadCheckedItems() -> [String] {
        return userDefaults?.stringArray(forKey: checkedItemsKey) ?? []
    }
    
    func toggle(meal: String) {
        var items = loadCheckedItems()
        if let index = items.firstIndex(of: meal) {
            items.remove(at: index)
        } else {
            items.append(meal)
        }
        save(checkedItems: items)
        save(lastEatDate: Date())
    }
}
