import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: Settings
    
    var body: some View {
        TabView {
            GeneralSettingsView(settings: settings)
                .tabItem {
                    Label("General", systemImage: "gear")
                }
            
            DisplaySettingsView(settings: settings)
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