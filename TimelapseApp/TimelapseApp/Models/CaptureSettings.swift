import Foundation

struct CaptureSettings: Equatable {
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
        
        var size: CGSize {
            if let dims = dimensions {
                return CGSize(width: dims.width, height: dims.height)
            }
            // Default size if original is selected (could also throw an error here)
            return CGSize(width: 1920, height: 1080)
        }
    }
    
    struct VideoSettings: Equatable {
        var resolution: Resolution = .res1080p
        var frameRate: Int = 30
        var showTimestamp: Bool = false
        var timestampFormat: String = "yyyy-MM-dd HH:mm:ss"
        var timestampPosition: TimestampPosition = .bottomRight
        
        enum TimestampPosition: String, CaseIterable {
            case topLeft, topRight, bottomLeft, bottomRight
        }
        
        static func == (lhs: VideoSettings, rhs: VideoSettings) -> Bool {
            lhs.resolution == rhs.resolution &&
            lhs.frameRate == rhs.frameRate &&
            lhs.showTimestamp == rhs.showTimestamp &&
            lhs.timestampFormat == rhs.timestampFormat &&
            lhs.timestampPosition == rhs.timestampPosition
        }
    }
    
    var resolution: Resolution = .original
    var blurEnabled: Bool = false
    var blurRadius: Float = 10.0
    var awayThresholdMinutes: Double = 5.0
    var awayDetectionEnabled: Bool = true
    var videoSettings = VideoSettings()
    
    static func == (lhs: CaptureSettings, rhs: CaptureSettings) -> Bool {
        lhs.resolution == rhs.resolution &&
        lhs.blurEnabled == rhs.blurEnabled &&
        lhs.blurRadius == rhs.blurRadius &&
        lhs.awayThresholdMinutes == rhs.awayThresholdMinutes &&
        lhs.awayDetectionEnabled == rhs.awayDetectionEnabled &&
        lhs.videoSettings == rhs.videoSettings
    }
} 