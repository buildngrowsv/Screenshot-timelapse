import Foundation
import ScreenCaptureKit

@MainActor
class ScreenshotManager: ObservableObject {
    private let screenCaptureService: ScreenCaptureService
    private var timer: Timer?
    
    // Published properties for the UI
    @Published var isCapturing = false
    @Published var captureIntervalMinutes: Double = 1.0
    
    // Properties for display management
    @Published private(set) var availableDisplays: [SCDisplay] = []
    @Published var selectedDisplays: Set<SCDisplay> = []
    
    init(screenCaptureService: ScreenCaptureService) {
        self.screenCaptureService = screenCaptureService
    }
    
    // Fetch available displays
    func fetchDisplays() async {
        await screenCaptureService.fetchAvailableDisplays()
        self.availableDisplays = screenCaptureService.availableDisplays
        self.selectedDisplays = screenCaptureService.selectedDisplays
    }
    
    // Start capturing screenshots at intervals
    func startCapturing() {
        guard !isCapturing else { return }
        isCapturing = true
        
        // Convert minutes to seconds
        let intervalSeconds = captureIntervalMinutes * 60
        
        // Take initial screenshot
        captureScreenshot()
        
        // Set up timer for subsequent screenshots
        timer = Timer.scheduledTimer(withTimeInterval: intervalSeconds, repeats: true) { [weak self] _ in
            self?.captureScreenshot()
        }
    }
    
    // Stop capturing screenshots
    func stopCapturing() {
        timer?.invalidate()
        timer = nil
        isCapturing = false
    }
    
    // Capture a screenshot
    private func captureScreenshot() {
        Task {
            do {
                // Update selected displays in the service
                screenCaptureService.selectedDisplays = self.selectedDisplays
                try await screenCaptureService.captureScreenshot()
            } catch {
                print("Error capturing screenshot: \(error)")
            }
        }
    }
}