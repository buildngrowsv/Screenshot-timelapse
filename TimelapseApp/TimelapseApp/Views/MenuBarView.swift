import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject private var menuBarController: MenuBarController
    @ObservedObject private var screenshotManager: ScreenshotManager
    @State private var selectedTab = 0
    @State private var previewWindow: NSWindow?
    
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
                            in: 0.01...60.01,
                            step: 1
                        )
                        Text(String(format: "%.2f", screenshotManager.captureIntervalMinutes))
                            .monospacedDigit()
                            .frame(width: 45)
                    }
                }
                
                // Control buttons
                HStack(spacing: 12) {
                    Button(action: {
                        if screenshotManager.isCapturing {
                            print("🔴 Stop button pressed")
                            screenshotManager.stopCapturing()
                        } else {
                            print("🟢 Start button pressed")
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
                
                // Add test button at the bottom
                Section {
                    Button("Test Away Prompt") {
                        menuBarController.screenshotManager.awayDetectionService.testAwayPrompt()
                    }
                }
            }
            .padding()
            .tabItem {
                Label("Capture", systemImage: "camera")
            }
            .tag(0)
            
            // Away History Tab
            Form {
                if screenshotManager.awayPeriods.isEmpty {
                    Text("No away periods recorded")
                        .foregroundColor(.secondary)
                } else {
                    List {
                        ForEach(screenshotManager.awayPeriods) { period in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(period.startTime, style: .date)
                                    .font(.headline)
                                Text("Duration: \(formatDuration(period.duration))")
                                    .font(.subheadline)
                                if !period.activity.isEmpty {
                                    Text("Activity: \(period.activity)")
                                        .font(.body)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .tabItem {
                Label("Away History", systemImage: "clock.arrow.circlepath")
            }
            
            // Settings Tab (without away history)
            SettingsView(screenshotManager: screenshotManager)
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
        .frame(width: 300)
        .task {
            await screenshotManager.fetchDisplays()
        }
    }
    
    private func showPreviewWindow() {
        if let existing = previewWindow {
            existing.makeKeyAndOrderFront(nil)
            return
        }
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 500),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Live Preview"
        window.contentView = NSHostingView(
            rootView: LivePreviewWindow(screenshotManager: screenshotManager)
        )
        window.center()
        
        // Add these lines to make window stay on top
        window.level = .floating  // Makes window stay on top
        window.isMovableByWindowBackground = true  // Allows dragging from anywhere in the window
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]  // Shows on all spaces/desktops
        
        window.makeKeyAndOrderFront(nil)
        
        // Keep window reference
        previewWindow = window
        
        // Clean up reference when window closes
        window.isReleasedWhenClosed = false
        NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: window,
            queue: .main
        ) { _ in
            previewWindow = nil
        }
    }
    
    private func formatDuration(_ interval: TimeInterval) -> String {
        let minutes = Int(interval / 60)
        if minutes < 60 {
            return "\(minutes) minutes"
        } else {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            return "\(hours)h \(remainingMinutes)m"
        }
    }
} 