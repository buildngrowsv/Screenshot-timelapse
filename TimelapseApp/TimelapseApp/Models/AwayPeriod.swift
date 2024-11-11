import Foundation

struct AwayPeriod: Codable, Identifiable {
    let id: UUID
    let startTime: Date
    let endTime: Date
    let duration: TimeInterval
    var activity: String
    
    init(startTime: Date, endTime: Date, activity: String = "") {
        self.id = UUID()
        self.startTime = startTime
        self.endTime = endTime
        self.duration = endTime.timeIntervalSince(startTime)
        self.activity = activity
    }
} 