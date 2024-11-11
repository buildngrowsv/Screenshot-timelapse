import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject private var menuBarController: MenuBarController
    @ObservedObject private var screenshotManager: ScreenshotManager
    @State private var selectedTab = 0
    
    init(menuBarController: MenuBarController) {
        self.screenshotManager = menuBarController.screenshotManager
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Main Capture Tab
            VStack(spacing: 16) {
                // Display selection section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Select Display:")
                        .font(.caption)
                    
                    ForEach(screenshotManager.availableDisplays, id: \.displayID) { display in
                        RadioButton(
                            selected: Binding(
                                get: { screenshotManager.selectedDisplays.contains(display) },
                                set: { isSelected in
                                    if isSelected {
                                        // Clear previous selection and set new one
                                        screenshotManager.selectedDisplays.removeAll()
                                        screenshotManager.selectedDisplays.insert(display)
                                    }
                                }
                            ),
                            content: {
                                DisplayPreviewView(display: display)
                            }
                        )
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
                
                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
            }
            .padding()
            .tabItem {
                Label("Capture", systemImage: "camera")
            }
            .tag(0)
            
            // Settings Tab
            Form {
                Section("Resolution") {
                    Picker("Screenshot Resolution", selection: $screenshotManager.settings.resolution) {
                        ForEach(CaptureSettings.Resolution.allCases) { resolution in
                            Text(resolution.rawValue).tag(resolution)
                        }
                    }
                }
                
                Section("Blur Effect") {
                    Toggle("Enable Blur", isOn: $screenshotManager.settings.blurEnabled)
                    
                    if screenshotManager.settings.blurEnabled {
                        HStack {
                            Text("Blur Intensity")
                            Slider(
                                value: $screenshotManager.settings.blurRadius,
                                in: 1...50
                            )
                            Text("\(Int(screenshotManager.settings.blurRadius))")
                                .monospacedDigit()
                                .frame(width: 30)
                        }
                    }
                }
            }
            .padding()
            .tabItem {
                Label("Settings", systemImage: "gear")
            }
            .tag(1)
        }
        .frame(width: 300)
        .task {
            await screenshotManager.fetchDisplays()
        }
    }
} 