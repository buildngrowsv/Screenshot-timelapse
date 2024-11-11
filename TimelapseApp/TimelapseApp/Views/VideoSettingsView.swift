import SwiftUI

struct VideoSettingsView: View {
    @ObservedObject var settings: Settings
    
    var body: some View {
        Form {
            Section("Video Output") {
                Picker("Output Resolution", selection: $settings.outputResolution) {
                    ForEach(Settings.Resolution.allCases, id: \.self) { resolution in
                        Text(resolution.rawValue)
                    }
                }
                
                HStack {
                    Text("Frame Rate:")
                    TextField("FPS", value: $settings.frameRate, formatter: NumberFormatter())
                        .frame(width: 100)
                    Text("fps")
                }
            }
            
            Section("Timestamp") {
                Toggle("Show Timestamp", isOn: $settings.showTimestamp)
                
                if settings.showTimestamp {
                    ColorPicker("Timestamp Color", selection: $settings.timestampColor)
                    
                    Slider(value: $settings.timestampSize, in: 8...72) {
                        Text("Timestamp Size")
                    }
                    
                    Toggle("Add Border", isOn: $settings.timestampBorder)
                    if settings.timestampBorder {
                        ColorPicker("Border Color", selection: $settings.timestampBorderColor)
                    }
                }
            }
            
            Section("Storage Estimates") {
                Text("Estimated storage per hour: \(settings.estimatedStoragePerHour, specifier: "%.1f") GB")
                Text("Estimated video length: \(settings.estimatedVideoLength, specifier: "%.1f") minutes")
            }
        }
    }
} 