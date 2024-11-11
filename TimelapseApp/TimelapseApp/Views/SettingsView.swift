import SwiftUI

struct SettingsView: View {
    @ObservedObject var screenshotManager: ScreenshotManager
    
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
        }
        .padding()
        .frame(width: 300)
    }
} 