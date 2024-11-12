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
        print("📸 Stopping capture session...")
        timer?.invalidate()
        timer = nil
        
        // Generate video
        Task {
            do {
                print("🎥 Starting video generation...")
                try await endSession()
                print("✅ Video generation completed")
            } catch {
                print("❌ Error generating video: \(error)")
            }
        }
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
    
    private func cleanupScreenshots(_ screenshots: [URL]) {
        for screenshot in screenshots {
            try? FileManager.default.removeItem(at: screenshot)
        }
        print("🧹 Cleaned up \(screenshots.count) screenshots")
    }
    
    func endSession() async throws {
        guard isCapturing else {
            print("⚠️ Cannot end session: not currently capturing")
            return
        }
        isCapturing = false
        
        print("🔍 Fetching screenshots...")
        let screenshots = try await fetchScreenshots()
        print("📊 Found \(screenshots.count) screenshots")
        
        guard !screenshots.isEmpty else {
            throw NSError(domain: "VideoProcessor", code: 2, userInfo: [
                NSLocalizedDescriptionKey: "No screenshots found to process"
            ])
        }
        
        print("🎬 Creating video processor...")
        let videoProcessor = VideoProcessor(settings: settings)
        print("🎥 Processing timelapse video...")
        let videoURL = try await videoProcessor.createTimelapse(
            screenshots: screenshots,
            awayPeriods: awayPeriods
        )
        
        print("✅ Timelapse video created at: \(videoURL.path)")
        
        // Cleanup screenshots after successful video creation
        cleanupScreenshots(screenshots)
    }
    
    private func fetchScreenshots() async throws -> [URL] {
        print("🔍 Looking for screenshots...")
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let resourceKeys = Set<URLResourceKey>([.creationDateKey])
        
        // Get all screenshots
        let screenshots = try FileManager.default.contentsOfDirectory(
            at: documentsPath,
            includingPropertiesForKeys: Array(resourceKeys),
            options: .skipsHiddenFiles
        ).filter { $0.pathExtension == "png" && $0.lastPathComponent.hasPrefix("screenshot_") }
        
        print("📁 Found \(screenshots.count) screenshots in \(documentsPath.path)")
        
        // Sort by creation date
        let sortedScreenshots = screenshots.sorted { url1, url2 in
            guard let date1 = try? url1.resourceValues(forKeys: resourceKeys).creationDate,
                  let date2 = try? url2.resourceValues(forKeys: resourceKeys).creationDate else {
                return false
            }
            return date1 < date2
        }
        
        print("📊 Sorted screenshots: \(sortedScreenshots.count)")
        sortedScreenshots.forEach { print("   📷 \($0.lastPathComponent)") }
        
        return sortedScreenshots
    }
}