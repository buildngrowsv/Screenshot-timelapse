import SwiftUI

struct DisplaySettingsView: View {
    @ObservedObject var settings: Settings
    @ObservedObject var displayManager: DisplayManager
    
    var body: some View {
        Form {
            Section("Display Selection") {
                ForEach(displayManager.availableDisplays) { display in
                    Toggle(display.displayName, isOn: Binding(
                        get: { settings.selectedDisplays.contains(display.id) },
                        set: { isSelected in
                            if isSelected {
                                settings.selectedDisplays.insert(display.id)
                            } else {
                                settings.selectedDisplays.remove(display.id)
                            }
                        }
                    ))
                    Text(display.resolution)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if displayManager.availableDisplays.isEmpty {
                Text("No displays detected")
                    .foregroundColor(.secondary)
            }
            
            Section("Storage Estimation") {
                StorageEstimationView(settings: settings)
            }
        }
    }
}

struct StorageEstimationView: View {
    @ObservedObject var settings: Settings
    
    var estimatedStoragePerHour: Double {
        // Calculate based on resolution and compression
        let (width, height) = settings.screenshotResolution.dimensions
        let bytesPerPixel = 4 // RGBA
        let screenshotsPerHour = 3600 / settings.screenshotInterval
        let compressionRatio = 0.5 // Estimated JPEG compression ratio
        
        return Double(width * height * bytesPerPixel) * screenshotsPerHour * compressionRatio / (1024 * 1024 * 1024) // In GB
    }
    
    var estimatedVideoLength: TimeInterval {
        let screenshotsPerSecond = 30 // Target FPS
        let totalScreenshots = (3600 * 8) / settings.screenshotInterval // 8 hours of screenshots
        return totalScreenshots / Double(screenshotsPerSecond)
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Storage per hour: \(String(format: "%.2f", estimatedStoragePerHour)) GB")
            Text("8-hour session video length: \(String(format: "%.1f", estimatedVideoLength)) seconds")
        }
    }
}