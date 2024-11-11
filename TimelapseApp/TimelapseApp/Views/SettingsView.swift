import SwiftUI

struct SettingsView: View {
    @ObservedObject var screenshotManager: ScreenshotManager
    @State private var previewWindow: NSWindow?
    
    var body: some View {
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
            
            Section {
                Button("Show Live Preview") {
                    showPreviewWindow()
                }
            }
        }
        .padding()
        .frame(width: 300)
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
} 