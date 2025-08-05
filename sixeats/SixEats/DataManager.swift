
import Foundation
import CoreFoundation

struct DataManager {
    static let shared = DataManager()
    private let userDefaults = UserDefaults(suiteName: "group.com.paavandesign.SixEats")

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
        // Fast path: perform day reset check once and load items directly
        checkAndResetIfNewDay()
        var items = userDefaults?.stringArray(forKey: checkedItemsKey) ?? []
        
        if let index = items.firstIndex(of: meal) {
            items.remove(at: index)
        } else {
            items.append(meal)
        }
        
        // Batch the save operations for better performance
        let currentDate = Date()
        userDefaults?.set(items, forKey: checkedItemsKey)
        userDefaults?.set(currentDate, forKey: lastEatDateKey)
        userDefaults?.synchronize() // Force immediate sync for widget updates
    }
    
    // Ultra-fast toggle method for immediate widget updates
    func toggleImmediately(meal: String) {
        guard let userDefaults = userDefaults else { return }
        
        // Skip day reset check for speed - handle it on next regular toggle
        var items = userDefaults.stringArray(forKey: checkedItemsKey) ?? []
        
        // Toggle the item
        if let index = items.firstIndex(of: meal) {
            items.remove(at: index)
        } else {
            items.append(meal)
        }
        
        // Immediate synchronous updates - no batching delay
        let currentDate = Date()
        userDefaults.set(items, forKey: checkedItemsKey)
        userDefaults.set(currentDate, forKey: lastEatDateKey)
        
        // Force immediate disk write - critical for widget updates
        userDefaults.synchronize()
        
    }
    
    private func checkAndResetIfNewDay() {
        guard let userDefaults = userDefaults else { return }
        
        let today = Date()
        
        // Get the last reset date
        let lastResetDate = userDefaults.object(forKey: lastResetDateKey) as? Date
        
        // If no reset date exists, or if it's a new calendar day, reset the checked items
        if let lastReset = lastResetDate {
            if !Calendar.current.isDate(today, inSameDayAs: lastReset) {
                resetForNewDay()
            }
        } else {
            // First time - set the reset date but don't clear items
            userDefaults.set(today, forKey: lastResetDateKey)
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
