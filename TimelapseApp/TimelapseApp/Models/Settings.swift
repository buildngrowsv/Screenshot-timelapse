import Foundation
import CoreGraphics
import SwiftUI

class Settings: ObservableObject {
    enum Resolution: String, CaseIterable {
        case original = "Original"
        case uhd4k = "4K UHD (3840x2160)"
        case fhd = "Full HD (1920x1080)"
        case hd = "HD (1280x720)"
    }
    
    @Published var selectedDisplays: Set<CGDirectDisplayID> = []
    @Published var screenshotInterval: TimeInterval = 30
    @Published var screenshotResolution: Resolution = .original
    @Published var outputResolution: Resolution = .uhd4k
    @Published var blurEnabled: Bool = false
    @Published var blurRadius: Double = 5
    @Published var awayThreshold: Double = 5
    @Published var sessionEndThreshold: Double = 8
    @Published var frameRate: Double = 30
    @Published var showTimestamp: Bool = false
    @Published var timestampColor: Color = .white
    @Published var timestampSize: Double = 24
    @Published var timestampBorder: Bool = false
    @Published var timestampBorderColor: Color = .black
    
    var estimatedStoragePerHour: Double {
        // Implementation pending - calculate based on resolution and interval
        return 0.0
    }
    
    var estimatedVideoLength: Double {
        // Implementation pending - calculate based on session length and frame rate
        return 0.0
    }
}