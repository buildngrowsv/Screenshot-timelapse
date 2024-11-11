import Foundation

func formatDuration(_ interval: TimeInterval) -> String {
    let minutes = Int(interval / 60)
    if minutes < 60 {
        return "\(minutes) minutes"
    } else {
        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        return "\(hours) hours \(remainingMinutes) minutes"
    }
} 