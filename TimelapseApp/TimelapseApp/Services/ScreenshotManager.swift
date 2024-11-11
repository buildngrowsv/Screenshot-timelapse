import Foundation

@MainActor
class ScreenshotManager: ObservableObject {
    private let screenCaptureService: ScreenCaptureService
    private var timer: Timer?
    
    @Published var isCapturing = false
    @Published var captureIntervalMinutes: Double = 1.0
    
    init(screenCaptureService: ScreenCaptureService) {
        self.screenCaptureService = screenCaptureService
    }
    
    func startCapturing() {
        guard !isCapturing else { return }
        isCapturing = true
        
        // Convert minutes to seconds for the timer
        let intervalSeconds = captureIntervalMinutes * 60
        
        // Take initial screenshot
        captureScreenshot()
        
        // Create timer for subsequent screenshots
        timer = Timer.scheduledTimer(withTimeInterval: intervalSeconds, repeats: true) { [weak self] _ in
            self?.captureScreenshot()
        }
    }
    
    func stopCapturing() {
        timer?.invalidate()
        timer = nil
        isCapturing = false
    }
    
    private func captureScreenshot() {
        Task {
            try? await screenCaptureService.captureScreenshot()
        }
    }
} 