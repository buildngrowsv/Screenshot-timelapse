import SwiftUI

struct DisplaySettingsView: View {
    @ObservedObject var settings: Settings
    
    var body: some View {
        Form {
            Section("Display Selection") {
                ForEach(NSScreen.screens, id: \.displayID) { screen in
                    Toggle(isOn: Binding(
                        get: { settings.selectedDisplays.contains(screen.displayID) },
                        set: { isSelected in
                            if isSelected {
                                settings.selectedDisplays.insert(screen.displayID)
                            } else {
                                settings.selectedDisplays.remove(screen.displayID)
                            }
                        }
                    )) {
                        Text("Display \(screen.displayID)")
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
        }
    }
} 