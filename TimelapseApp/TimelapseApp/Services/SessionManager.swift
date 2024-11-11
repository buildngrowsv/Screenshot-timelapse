import Foundation

class SessionManager: ObservableObject {
    @Published var currentSession: Session?
    @Published var isRecording: Bool = false
    
    private let screenCaptureService: ScreenCaptureService
    private let settings: Settings
    
    init(settings: Settings) {
        self.settings = settings
        self.screenCaptureService = ScreenCaptureService(settings: settings)
    }
    
    func startNewSession() {
        currentSession = Session(
            id: UUID(),
            startTime: Date(),
            awayPeriods: [],
            screenshots: []
        )
        isRecording = true
        screenCaptureService.startCapturing()
    }
    
    func stopSession() {
        currentSession?.endTime = Date()
        isRecording = false
        screenCaptureService.stopCapturing()
        processSession()
    }
    
    private func processSession() {
        // Process screenshots into video
        // Implementation pending
    }
}