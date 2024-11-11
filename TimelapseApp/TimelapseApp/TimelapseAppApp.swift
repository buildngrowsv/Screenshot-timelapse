import SwiftUI

@main
struct TimelapseAppApp: App {
    @StateObject private var settings = Settings()
    @StateObject private var sessionManager: SessionManager
    
    init() {
        let settings = Settings()
        _settings = StateObject(wrappedValue: settings)
        _sessionManager = StateObject(wrappedValue: SessionManager(settings: settings))
    }
    
    var body: some Scene {
        MenuBarExtra("Timelapse", systemImage: "record.circle") {
            MenuBarView(sessionManager: sessionManager, settings: settings)
        }
        .menuBarExtraStyle(.window)
        
        Window("Settings", id: "settings") {
            SettingsView(settings: settings)
        }
        .defaultSize(width: 480, height: 300)
    }
}
