import Foundation

class Settings: ObservableObject {
    @Published var screenshotInterval: TimeInterval = 30 // seconds
    @Published var selectedDisplays: Set<CGDirectDisplayID> = []
    @Published var screenshotResolution: Resolution = .original
    @Published var outputResolution: Resolution = .fourK
    @Published var blurEnabled: Bool = false
    @Published var blurRadius: Double = 5.0
    @Published var awayThreshold: TimeInterval = 300 // 5 minutes
    @Published var sessionEndThreshold: TimeInterval = 14400 // 4 hours
    @Published var timestampEnabled: Bool = false
    @Published var timestampSize: Double = 14
    @Published var timestampColor: CGColor = CGColor(red: 1, green: 1, blue: 1, alpha: 1)
    @Published var timestampBorderEnabled: Bool = false
    @Published var timestampBorderColor: CGColor = CGColor(red: 0, green: 0, blue: 0, alpha: 1)
    
    enum Resolution: String, CaseIterable {
        case original = "Original"
        case fourK = "4K (3840x2160)"
        case twoK = "2K (2560x1440)"
        case fullHD = "Full HD (1920x1080)"
        case hd = "HD (1280x720)"
        
        var dimensions: (width: Int, height: Int) {
            switch self {
            case .original: return (0, 0) // Will be determined at runtime
            case .fourK: return (3840, 2160)
            case .twoK: return (2560, 1440)
            case .fullHD: return (1920, 1080)
            case .hd: return (1280, 720)
            }
        }
    }
}