import Foundation
import AppKit

class DisplayManager: ObservableObject {
    @Published var availableDisplays: [Display] = []
    
    struct Display: Identifiable {
        let id: CGDirectDisplayID
        let name: String
        let resolution: String
        var isMain: Bool
        
        var displayName: String {
            return isMain ? "\(name) (Main Display)" : name
        }
    }
    
    init() {
        updateDisplays()
        
        // Monitor display configuration changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(displayConfigurationDidChange),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }
    
    func updateDisplays() {
        var onlineDisplays: UInt32 = 0
        var displayIDs: [CGDirectDisplayID] = Array(repeating: 0, count: Int(INT32_MAX))
        
        guard CGGetOnlineDisplayList(UInt32(INT32_MAX), &displayIDs, &onlineDisplays) == .success else {
            return
        }
        
        availableDisplays = Array(displayIDs.prefix(Int(onlineDisplays))).map { displayID in
            let name = getDisplayName(displayID)
            let resolution = getDisplayResolution(displayID)
            let isMain = CGMainDisplayID() == displayID
            
            return Display(
                id: displayID,
                name: name,
                resolution: resolution,
                isMain: isMain
            )
        }
    }
    
    private func getDisplayName(_ displayID: CGDirectDisplayID) -> String {
        guard let info = IODisplayCreateInfoDictionary(IOServicePortFromCGDisplayID(displayID), IOOptionBits(kIODisplayOnlyPreferredName)).takeRetainedValue() as? [String: AnyObject],
              let names = info[kDisplayProductName] as? [String: String],
              let name = names.first?.value else {
            return "Display \(displayID)"
        }
        return name
    }
    
    private func getDisplayResolution(_ displayID: CGDirectDisplayID) -> String {
        let width = CGDisplayPixelsWide(displayID)
        let height = CGDisplayPixelsHigh(displayID)
        return "\(width)×\(height)"
    }
    
    @objc private func displayConfigurationDidChange(_ notification: Notification) {
        updateDisplays()
    }
}