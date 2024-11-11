import SwiftUI

struct MenuBarView: View {
    @ObservedObject var sessionManager: SessionManager
    @ObservedObject var settings: Settings
    @Environment(\.openWindow) private var openWindow
    
    var body: some View {
        VStack {
            Button(sessionManager.isRecording ? "Stop Recording" : "Start Recording") {
                if sessionManager.isRecording {
                    sessionManager.stopSession()
                } else {
                    sessionManager.startNewSession()
                }
            }
            
            Divider()
            
            Button("Settings...") {
                openWindow(id: "settings")
            }
            
            Divider()
            
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        }
        .padding(.vertical, 5)
    }
}