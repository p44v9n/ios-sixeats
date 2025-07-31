//
//  sixeatsApp.swift
//  sixeats
//
//  Created by Paavan Buddhdev on 02/07/2025.
//

import SwiftUI
import WidgetKit

@main
struct sixeatsApp: App {
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                // Call widget reload as soon as app becomes active for instant refresh
                WidgetCenter.shared.reloadTimelines(ofKind: "SixEatsWidget")
            }
        }
    }
}
