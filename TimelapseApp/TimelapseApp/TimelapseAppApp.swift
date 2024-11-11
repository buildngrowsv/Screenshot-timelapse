import SwiftUI

@main
struct TimelapseAppApp: App {
    @StateObject private var settings = Settings()
    @StateObject private var sessionManager: SessionManager
    @StateObject private var displayManager = DisplayManager()
    
    init() {
        let settings = Settings()
        _settings = StateObject(wrappedValue: settings)
        _sessionManager = StateObject(wrappedValue: SessionManager(settings: settings))
    }
    
    var body: some Scene {
        MenuBarExtra {
            MenuBarView(sessionManager: sessionManager, settings: settings)
        } label: {
            Image(systemName: sessionManager.isRecording ? "record.circle.fill" : "record.circle")
        }
        
        WindowGroup {
            EmptyView()
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 0, height: 0)
        
        Settings {
            SettingsView(settings: settings, displayManager: displayManager)
        }
    }
}