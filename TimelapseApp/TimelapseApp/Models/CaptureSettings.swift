import Foundation

struct CaptureSettings {
    enum Resolution: String, CaseIterable, Identifiable {
        case original = "Original Size"
        case res1080p = "1080p"
        case res720p = "720p"
        case res480p = "480p"
        case res240p = "240p"
        
        var id: String { rawValue }
        
        var dimensions: (width: Int, height: Int)? {
            switch self {
            case .original: return nil
            case .res1080p: return (1920, 1080)
            case .res720p: return (1280, 720)
            case .res480p: return (854, 480)
            case .res240p: return (426, 240)
            }
        }
    }
    
    var resolution: Resolution = .original
    var blurEnabled: Bool = false
    var blurRadius: Float = 10.0  // Default blur radius
} 