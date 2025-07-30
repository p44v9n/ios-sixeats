
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

private struct CheckboxView: View {
    let meal: String
    let isChecked: Bool
    
    var body: some View {
        Button(intent: ToggleMealIntent(mealItem: meal)) {
            HStack(spacing: 4) {
                Image(systemName: isChecked ? "circle.fill" : "circle")
                    .font(.system(size: 13))
                    .foregroundColor(Color(red: 1, green: 59/255, blue: 47/255))
                
                Text(meal)
                    .font(.system(size: 13, weight: .medium, design: .default))
                    .strikethrough(isChecked, color: Color(red: 1, green: 59/255, blue: 47/255))
                    .foregroundColor(Color(red: 1, green: 59/255, blue: 47/255))
                    .opacity(isChecked ? 0.4 : 1.0)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SixEatsWidgetEntryView : View {
    var entry: Provider.Entry
    
    private func timeSinceLastEat() -> (hours: Int, minutes: Int) {
        let timeInterval = entry.date.timeIntervalSince(entry.lastEatDate)
        let totalMinutes = Int(timeInterval / 60)
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        return (hours, minutes)
    }
    
    private func isChecked(_ item: String) -> Bool {
        entry.checkedItems.contains(item)
    }
    
    var body: some View {
        Grid(alignment: .leading, horizontalSpacing: 30, verticalSpacing: 27) {
            GridRow {
                VStack(alignment: .leading, spacing: 2) {
                    Spacer()
                    
                    let timeSince = timeSinceLastEat()
                    
                    HStack(spacing: 4) {
                        Text("\(timeSince.hours)h \(timeSince.minutes)m")
                            .font(.system(size: 19, weight: .medium, design: .default))
                            .foregroundColor(.black)
                        
                        Button(intent: RefreshIntent()) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    Text("since you last ate")
                        .font(.system(size: 10, weight: .medium, design: .default))
                        .foregroundColor(.black)
                        .opacity(0.5)
                }
                .gridColumnAlignment(.leading)
                
                VStack(alignment: .leading, spacing: 27) {
                    CheckboxView(meal: "Breakfast", isChecked: isChecked("Breakfast"))
                    CheckboxView(meal: "Lunch", isChecked: isChecked("Lunch"))
                    CheckboxView(meal: "Dinner", isChecked: isChecked("Dinner"))
                }
                .gridColumnAlignment(.leading)
                
                VStack(alignment: .leading, spacing: 27) {
                    CheckboxView(meal: "Snack 1", isChecked: isChecked("Snack 1"))
                    CheckboxView(meal: "Snack 2", isChecked: isChecked("Snack 2"))
                    CheckboxView(meal: "Snack 3", isChecked: isChecked("Snack 3"))
                }
                .gridColumnAlignment(.leading)
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 6)
        .containerBackground(for: .widget) {
            Color(red: 254/255, green: 254/255, blue: 254/255)
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
