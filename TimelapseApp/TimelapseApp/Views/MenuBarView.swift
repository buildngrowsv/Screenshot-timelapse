import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject private var menuBarController: MenuBarController
    
    var body: some View {
        VStack(spacing: 12) {
            Button("Capture Screenshot") {
                menuBarController.captureScreenshot()
            }
            .buttonStyle(.borderedProminent)
            
            Divider()
            
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        }
        .padding()
        .frame(width: 200)
    }
} 