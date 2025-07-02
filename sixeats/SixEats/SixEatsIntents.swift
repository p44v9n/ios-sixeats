import AppIntents

struct ToggleMealIntent: AppIntent {
    static var title: LocalizedStringResource = "Toggle Meal"

    @Parameter(title: "Meal")
    var meal: String

    init(meal: String) {
        self.meal = meal
    }
    
    init() {
        
    }

    func perform() async throws -> some IntentResult {
        DataManager.shared.toggle(meal: meal)
        return .result()
    }
}
