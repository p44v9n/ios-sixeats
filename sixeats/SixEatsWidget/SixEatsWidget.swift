//
//  SixEatsWidget.swift
//  SixEatsWidget
//
//  Created by Paavan Buddhdev on 02/07/2025.
//

import WidgetKit
import SwiftUI
import AppIntents

@available(iOS 17.0, *)
struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Configuration"
    static var description = IntentDescription("Configure your Six Eats widget.")
}

@available(iOS 17.0, *)
struct Provider: AppIntentTimelineProvider {
    typealias Entry = SimpleEntry
    typealias Intent = ConfigurationAppIntent
    
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), lastEatDate: Date(), checkedItems: ["Breakfast", "Snack 1"])
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        // Simplified snapshot - don't load from UserDefaults to prevent timeouts
        let defaultDate = Calendar.current.date(byAdding: .hour, value: -1, to: Date()) ?? Date()
        return SimpleEntry(date: Date(), lastEatDate: defaultDate, checkedItems: ["Breakfast"])
    }
    
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
        let currentDate = Date()
        
        // Try to load data, but use defaults if it fails or times out
        let dataManager = DataManager()
        let lastEatDate = dataManager.loadLastEatDate() ?? Calendar.current.date(byAdding: .hour, value: -1, to: currentDate) ?? currentDate
        let checkedItems = dataManager.loadCheckedItems()
        
        // Create fewer entries to reduce processing time
        var entries: [SimpleEntry] = []

        // Create entries every 15 minutes for the next 2 hours (8 entries total)
        for minuteOffset in stride(from: 0, to: 120, by: 15) {
            let entryDate = Calendar.current.date(byAdding: .minute, value: minuteOffset, to: currentDate)!
            let entry = SimpleEntry(date: entryDate, lastEatDate: lastEatDate, checkedItems: checkedItems)
            entries.append(entry)
        }

        // Schedule a reload every 2 hours instead of 4
        let nextReload = Calendar.current.date(byAdding: .hour, value: 2, to: currentDate)!
        return Timeline(entries: entries, policy: .after(nextReload))
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let lastEatDate: Date
    let checkedItems: [String]
}

struct DataManager {
    private let userDefaults: UserDefaults?
    
    init() {
        self.userDefaults = UserDefaults(suiteName: "group.com.example.SixEats")
    }
    
    func loadLastEatDate() -> Date? {
        guard let userDefaults = userDefaults else { 
            print("⚠️ Widget: Unable to access app group UserDefaults")
            return nil 
        }
        return userDefaults.object(forKey: "lastEatDate") as? Date
    }
    
    func loadCheckedItems() -> [String] {
        guard let userDefaults = userDefaults else { 
            print("⚠️ Widget: Unable to access app group UserDefaults")
            return [] 
        }
        checkAndResetIfNewDay()
        return userDefaults.stringArray(forKey: "checkedItems") ?? []
    }
    
    func saveLastEatDate(_ date: Date) {
        guard let userDefaults = userDefaults else {
            print("⚠️ Widget: Unable to save to app group UserDefaults")
            return
        }
        userDefaults.set(date, forKey: "lastEatDate")
    }
    
    func saveCheckedItems(_ items: [String]) {
        guard let userDefaults = userDefaults else {
            print("⚠️ Widget: Unable to save to app group UserDefaults")
            return
        }
        userDefaults.set(items, forKey: "checkedItems")
    }
    
    func toggleMealItem(_ item: String) {
        guard let userDefaults = userDefaults else {
            print("⚠️ Widget: Unable to access app group UserDefaults")
            return
        }
        
        var checkedItems = loadCheckedItems()
        if checkedItems.contains(item) {
            checkedItems.removeAll { $0 == item }
        } else {
            checkedItems.append(item)
            // Reset timer when checking an item
            saveLastEatDate(Date())
        }
        saveCheckedItems(checkedItems)
        
        // Force immediate sync
        userDefaults.synchronize()
    }
    
    private func checkAndResetIfNewDay() {
        guard let userDefaults = userDefaults else {
            print("⚠️ Widget: Unable to access app group UserDefaults for reset check")
            return
        }
        
        let calendar = Calendar.current
        let today = Date()
        
        // Get the last reset date
        let lastResetDate = userDefaults.object(forKey: "lastResetDate") as? Date
        
        // If no reset date exists, or if it's a new calendar day, reset the checked items
        if let lastReset = lastResetDate {
            if !calendar.isDate(today, inSameDayAs: lastReset) {
                resetForNewDay()
            }
        } else {
            // First time - set the reset date but don't clear items
            userDefaults.set(today, forKey: "lastResetDate")
        }
    }
    
    private func resetForNewDay() {
        guard let userDefaults = userDefaults else {
            print("⚠️ Widget: Unable to access app group UserDefaults for reset")
            return
        }
        
        // Clear checked items for the new day
        userDefaults.set([], forKey: "checkedItems")
        // Update the last reset date
        userDefaults.set(Date(), forKey: "lastResetDate")
        userDefaults.synchronize()
        
        print("📅 Widget: Reset checked items for new calendar day")
    }
}

@available(iOS 17.0, *)
struct RefreshIntent: AppIntent {
    static var title: LocalizedStringResource = "Refresh Widget"
    static var description = IntentDescription("Refresh the widget to update the timer")
    
    func perform() async throws -> some IntentResult {
        // Force widget to refresh immediately
        WidgetCenter.shared.reloadTimelines(ofKind: "SixEatsWidget")
        return .result()
    }
}

@available(iOS 17.0, *)
struct ToggleMealIntent: AppIntent {
    static var title: LocalizedStringResource = "Toggle Meal"
    static var description = IntentDescription("Toggle a meal item and reset timer")
    
    @Parameter(title: "Meal Item")
    var mealItem: String
    
    init() {}
    
    init(mealItem: String) {
        self.mealItem = mealItem
    }
    
    func perform() async throws -> some IntentResult {
        let dataManager = DataManager()
        dataManager.toggleMealItem(mealItem)
        
        // Force widget to refresh immediately after data changes
        WidgetCenter.shared.reloadTimelines(ofKind: "SixEatsWidget")
        
        return .result()
    }
}

struct SixEatsWidgetEntryView : View {
    var entry: Provider.Entry
    
    private let mainMeals = ["Breakfast", "Lunch", "Dinner"]
    private let snacks = ["Snack 1", "Snack 2", "Snack 3"]
    
    private func timeSinceLastEat() -> (hours: Int, minutes: Int) {
        let timeInterval = entry.date.timeIntervalSince(entry.lastEatDate)
        let totalMinutes = Int(timeInterval / 60)
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        return (hours, minutes)
    }
    
    private func shouldShowGoEat() -> Bool {
        let timeSince = timeSinceLastEat()
        return timeSince.hours >= 4 || (timeSince.hours == 3 && timeSince.minutes >= 30)
    }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Main content with 3 columns
                HStack(spacing: 16) {
                    // First column - Time since last eat
                    VStack(spacing: 4) {
                        Spacer()
                        let timeSince = timeSinceLastEat()
                        
                        if shouldShowGoEat() {
                            HStack(spacing: 4) {
                                Text("Go eat!")
                                    .font(.system(size: 20, weight: .bold, design: .rounded))
                                    .foregroundColor(.red)
                                
                                Button(intent: RefreshIntent()) {
                                    Image(systemName: "arrow.clockwise")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.secondary)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            
                            Text("\(timeSince.hours)h \(timeSince.minutes)m")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.secondary)
                        } else {
                            HStack(spacing: 4) {
                                Text("\(timeSince.hours)h \(timeSince.minutes)m")
                                    .font(.system(size: 20, weight: .bold, design: .rounded))
                                    .foregroundColor(.primary)
                                
                                Button(intent: RefreshIntent()) {
                                    Image(systemName: "arrow.clockwise")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.secondary)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            
                            Text("since you last ate")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    
                    // Second column - Main meals
                    VStack(spacing: 12) {
                        ForEach(mainMeals, id: \.self) { meal in
                            let isChecked = entry.checkedItems.contains(meal)
                            
                            Button(intent: ToggleMealIntent(mealItem: meal)) {
                                HStack(spacing: 6) {
                                    Circle()
                                        .fill(isChecked ? Color.red : Color.clear)
                                        .stroke(Color.red, lineWidth: 2)
                                        .frame(width: 14, height: 14)
                                    
                                    Text(meal)
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(isChecked ? .secondary : .primary)
                                        .strikethrough(isChecked)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .frame(maxWidth: .infinity)
                    
                    // Third column - Snacks
                    VStack(spacing: 12) {
                        ForEach(snacks, id: \.self) { snack in
                            let isChecked = entry.checkedItems.contains(snack)
                            
                            Button(intent: ToggleMealIntent(mealItem: snack)) {
                                HStack(spacing: 6) {
                                    Circle()
                                        .fill(isChecked ? Color.red : Color.clear)
                                        .stroke(Color.red, lineWidth: 2)
                                        .frame(width: 14, height: 14)
                                    
                                    Text(snack)
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(isChecked ? .secondary : .primary)
                                        .strikethrough(isChecked)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 4)
                
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

@available(iOS 17.0, *)
struct SixEatsWidget: Widget {
    let kind: String = "SixEatsWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            SixEatsWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Six Eats")
        .description("Track your daily meals and eating schedule.")
        .supportedFamilies([.systemMedium])
    }
}

@available(iOS 17.0, *)
#Preview(as: .systemMedium) {
    SixEatsWidget()
} timeline: {
    SimpleEntry(date: .now, lastEatDate: Calendar.current.date(byAdding: .hour, value: -2, to: .now)!, checkedItems: ["Breakfast", "Snack 1"])
    SimpleEntry(date: .now, lastEatDate: Calendar.current.date(byAdding: .hour, value: -3, to: .now)!, checkedItems: ["Breakfast"])
}
