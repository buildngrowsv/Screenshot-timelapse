import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject private var menuBarController: MenuBarController
    @ObservedObject private var screenshotManager: ScreenshotManager
    
    init(menuBarController: MenuBarController) {
        self.screenshotManager = menuBarController.screenshotManager
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Interval setting
            VStack(alignment: .leading, spacing: 8) {
                Text("Capture Interval (minutes):")
                    .font(.caption)
                
                HStack {
                    Slider(
                        value: $screenshotManager.captureIntervalMinutes,
                        in: 0.5...60.0,
                        step: 0.5
                    )
                    Text(String(format: "%.1f", screenshotManager.captureIntervalMinutes))
                        .monospacedDigit()
                        .frame(width: 35)
                }
            }
            
            // Control buttons
            HStack(spacing: 12) {
                Button(action: {
                    if screenshotManager.isCapturing {
                        screenshotManager.stopCapturing()
                    } else {
                        screenshotManager.startCapturing()
                    }
                }) {
                    Text(screenshotManager.isCapturing ? "Stop Capturing" : "Start Capturing")
                }
                .buttonStyle(.borderedProminent)
                .tint(screenshotManager.isCapturing ? .red : .green)
            }
            
            Divider()
            
            // Status indicator
            HStack {
                Circle()
                    .fill(screenshotManager.isCapturing ? .green : .gray)
                    .frame(width: 8, height: 8)
                Text(screenshotManager.isCapturing ? "Capturing" : "Stopped")
                    .font(.caption)
            }
            
            Divider()
            
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        }
        .padding()
        .frame(width: 250)
    }
} 