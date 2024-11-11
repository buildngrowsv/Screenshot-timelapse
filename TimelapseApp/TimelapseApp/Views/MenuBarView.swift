import SwiftUI

struct MenuBarView: View {
    @ObservedObject var sessionManager: SessionManager
    @ObservedObject var settings: Settings
    
    var body: some View {
        Menu {
            Button(sessionManager.isRecording ? "Stop Recording" : "Start Recording") {
                if sessionManager.isRecording {
                    sessionManager.stopSession()
                } else {
                    sessionManager.startNewSession()
                }
            }
            
            Divider()
            
            Button("Settings...") {
                // Open settings window
            }
            
            Divider()
            
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        } label: {
            Image(systemName: "record.circle")
                .foregroundColor(sessionManager.isRecording ? .red : .gray)
        }
    }
}