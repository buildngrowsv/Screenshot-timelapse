import SwiftUI
import ScreenCaptureKit

struct DisplaySettingsView: View {
    @ObservedObject var settings: Settings
    @State private var availableDisplays: [SCDisplay] = []
    
    var body: some View {
        Form {
            Section("Display Selection") {
                if availableDisplays.isEmpty {
                    Text("No displays available")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(availableDisplays, id: \.displayID) { display in
                        Toggle(
                            "Display \(display.displayID)",
                            isOn: Binding(
                                get: { settings.selectedDisplays.contains(display.displayID) },
                                set: { isSelected in
                                    if isSelected {
                                        settings.selectedDisplays.insert(display.displayID)
                                    } else {
                                        settings.selectedDisplays.remove(display.displayID)
                                    }
                                }
                            )
                        )
                    }
                }
            }
            
            Section("Screenshot Interval") {
                HStack {
                    Text("Take screenshot every:")
                    TextField("Seconds", value: $settings.screenshotInterval, formatter: NumberFormatter())
                        .frame(width: 100)
                    Text("seconds")
                }
            }
            
            Section("Storage Estimate") {
                Text("Estimated storage per hour: \(estimatedStoragePerHour, specifier: "%.1f") GB")
                    .foregroundColor(.secondary)
            }
        }
        .task {
            await loadAvailableDisplays()
        }
    }
    
    private var estimatedStoragePerHour: Double {
        // Rough estimation based on 4K screenshot size (~8MB per screenshot)
        let screenshotsPerHour = 3600 / settings.screenshotInterval
        let averageScreenshotSize = 8.0 // MB
        return (screenshotsPerHour * averageScreenshotSize * Double(availableDisplays.count)) / 1024
    }
    
    private func loadAvailableDisplays() async {
        do {
            let content = try await SCShareableContent.current
            await MainActor.run {
                availableDisplays = content.displays
            }
        } catch {
            print("Failed to load displays: \(error)")
        }
    }
}

#Preview {
    DisplaySettingsView(settings: Settings())
} 