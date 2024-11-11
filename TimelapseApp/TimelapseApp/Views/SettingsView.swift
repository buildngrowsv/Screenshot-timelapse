import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: Settings
    @ObservedObject var displayManager: DisplayManager
    
    var body: some View {
        TabView {
            GeneralSettingsView(settings: settings)
                .tabItem {
                    Label("General", systemImage: "gear")
                }
            
            DisplaySettingsView(settings: settings, displayManager: displayManager)
                .tabItem {
                    Label("Displays", systemImage: "display")
                }
            
            VideoSettingsView(settings: settings)
                .tabItem {
                    Label("Video", systemImage: "video")
                }
        }
        .padding()
        .frame(width: 500, height: 400)
    }
}

struct GeneralSettingsView: View {
    @ObservedObject var settings: Settings
    
    var body: some View {
        Form {
            Section("Screenshot Settings") {
                Picker("Screenshot Resolution", selection: $settings.screenshotResolution) {
                    ForEach(Settings.Resolution.allCases, id: \.self) { resolution in
                        Text(resolution.rawValue)
                    }
                }
                
                Toggle("Enable Blur", isOn: $settings.blurEnabled)
                if settings.blurEnabled {
                    Slider(value: $settings.blurRadius, in: 1...20) {
                        Text("Blur Radius")
                    }
                }
            }
            
            Section("Session Settings") {
                HStack {
                    Text("Away Threshold:")
                    TextField("Minutes", value: $settings.awayThreshold, formatter: NumberFormatter())
                }
                
                HStack {
                    Text("Auto-end Session After:")
                    TextField("Hours", value: $settings.sessionEndThreshold, formatter: NumberFormatter())
                }
            }
        }
    }
}

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
            }
            
            Section("Timestamp") {
                Toggle("Show Timestamp", isOn: $settings.timestampEnabled)
                
                if settings.timestampEnabled {
                    Slider(value: $settings.timestampSize, in: 8...36) {
                        Text("Size")
                    }
                    
                    ColorPicker("Color", selection: .init(
                        get: { Color(cgColor: settings.timestampColor) ?? .white },
                        set: { settings.timestampColor = $0.cgColor ?? .init(red: 1, green: 1, blue: 1, alpha: 1) }
                    ))
                    
                    Toggle("Show Border", isOn: $settings.timestampBorderEnabled)
                    
                    if settings.timestampBorderEnabled {
                        ColorPicker("Border Color", selection: .init(
                            get: { Color(cgColor: settings.timestampBorderColor) ?? .black },
                            set: { settings.timestampBorderColor = $0.cgColor ?? .init(red: 0, green: 0, blue: 0, alpha: 1) }
                        ))
                    }
                }
            }
        }
    }
}