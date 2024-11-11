import Foundation

struct Session: Codable, Identifiable {
    let id: UUID
    let startTime: Date
    var endTime: Date?
    var awayPeriods: [AwayPeriod]
    var screenshots: [Screenshot]
    
    struct AwayPeriod: Codable {
        let startTime: Date
        let endTime: Date
        let activity: String
    }
    
    struct Screenshot: Codable {
        let id: UUID
        let timestamp: Date
        let path: String
    }
}