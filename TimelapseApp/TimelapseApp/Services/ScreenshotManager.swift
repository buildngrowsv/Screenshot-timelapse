import Foundation
import ScreenCaptureKit
import Combine

@MainActor
class ScreenshotManager: ObservableObject {
    private let screenCaptureService: ScreenCaptureService
    let awayDetectionService: AwayDetectionService
    private var timer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    // Published properties for the UI
    @Published var isCapturing = false
    @Published var captureIntervalMinutes: Double = 1.0
    @Published var settings: CaptureSettings
    @Published var awayPeriods: [AwayPeriod] = []
    
    // Properties for display management
    @Published private(set) var availableDisplays: [SCDisplay] = []
    @Published var selectedDisplays: Set<SCDisplay> = []
    
    init(screenCaptureService: ScreenCaptureService) {
        let initialSettings = screenCaptureService.settings
        self.screenCaptureService = screenCaptureService
        self.settings = initialSettings
        self.awayDetectionService = AwayDetectionService(settings: initialSettings)
        
        // Defer observation setup to the next run loop
        Task { @MainActor in
            print("🔄 Setting up away periods observation")
            self.awayDetectionService.$awayPeriods
                .receive(on: DispatchQueue.main)
                .sink { [weak self] periods in
                    print("📝 Received updated away periods: \(periods.count)")
                    self?.awayPeriods = periods
                }
                .store(in: &cancellables)
            
            self.$settings
                .dropFirst()
                .sink { [weak self] newSettings in
                    self?.screenCaptureService.settings = newSettings
                    self?.awayDetectionService.updateSettings(newSettings)
                }
                .store(in: &cancellables)
        }
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