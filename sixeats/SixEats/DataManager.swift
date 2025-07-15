
import Foundation

struct DataManager {
    static let shared = DataManager()
    private let userDefaults = UserDefaults(suiteName: "group.com.example.SixEats")

    private let lastEatDateKey = "lastEatDate"
    private let checkedItemsKey = "checkedItems"
    private let lastResetDateKey = "lastResetDate"

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
        checkAndResetIfNewDay()
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
    
    private func checkAndResetIfNewDay() {
        let calendar = Calendar.current
        let today = Date()
        
        // Get the last reset date
        let lastResetDate = userDefaults?.object(forKey: lastResetDateKey) as? Date
        
        // If no reset date exists, or if it's a new calendar day, reset the checked items
        if let lastReset = lastResetDate {
            if !calendar.isDate(today, inSameDayAs: lastReset) {
                resetForNewDay()
            }
        } else {
            // First time - set the reset date but don't clear items
            userDefaults?.set(today, forKey: lastResetDateKey)
        }
    }
    
    private func resetForNewDay() {
        // Clear checked items for the new day
        userDefaults?.set([], forKey: checkedItemsKey)
        // Update the last reset date
        userDefaults?.set(Date(), forKey: lastResetDateKey)
        userDefaults?.synchronize()
    }
}
