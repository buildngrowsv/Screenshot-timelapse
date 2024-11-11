import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject private var menuBarController: MenuBarController
    @ObservedObject private var screenshotManager: ScreenshotManager
    
    init(menuBarController: MenuBarController) {
        self.screenshotManager = menuBarController.screenshotManager
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Display selection section
            VStack(alignment: .leading, spacing: 8) {
                Text("Select Displays:")
                    .font(.caption)
                
                ForEach(screenshotManager.availableDisplays, id: \.displayID) { display in
                    Toggle(isOn: Binding(
                        get: {
                            screenshotManager.selectedDisplays.contains(display)
                        },
                        set: { isSelected in
                            if isSelected {
                                screenshotManager.selectedDisplays.insert(display)
                            } else {
                                screenshotManager.selectedDisplays.remove(display)
                            }
                        }
                    )) {
                        Text("Display \(display.displayID)")
                            .font(.caption)
                    }
                }
            }
            
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
            
            Button("Settings") {
                let settingsWindow = NSWindow(
                    contentRect: NSRect(x: 0, y: 0, width: 300, height: 200),
                    styleMask: [.titled, .closable],
                    backing: .buffered,
                    defer: false
                )
                settingsWindow.title = "Settings"
                settingsWindow.contentView = NSHostingView(
                    rootView: SettingsView(screenshotManager: screenshotManager)
                )
                settingsWindow.center()
                settingsWindow.makeKeyAndOrderFront(nil)
            }
            
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        }
        .padding()
        .frame(width: 250)
        .task {
            await screenshotManager.fetchDisplays()
        }
    }
} 