import Foundation
import ScreenCaptureKit
import AppKit
import CoreMedia

@MainActor
class ScreenCaptureService: NSObject, ObservableObject {
    private var timer: Timer?
    private let settings: Settings
    private var stream: SCStream?
    
    init(settings: Settings) {
        self.settings = settings
        super.init()
    }
    
    private func captureScreens() async throws {
        // Get available screen content
        let content = try await SCShareableContent.current
        
        for display in settings.selectedDisplays.isEmpty ? [CGMainDisplayID()] : Array(settings.selectedDisplays) {
            // Find the corresponding SCDisplay
            guard let screen = content.displays.first(where: { $0.displayID == display }) else { continue }
            
            // Configure capture
            let filter = SCContentFilter(desktopIndependentWindow: .display(screen))
            let configuration = SCStreamConfiguration()
            
            // Create and start stream
            let stream = SCStream(filter: filter, configuration: configuration, delegate: self)
            try await stream.addStreamOutput(self, type: .screen, sampleHandlerQueue: DispatchQueue.main)
            try await stream.startCapture()
            
            // Store stream reference
            self.stream = stream
        }
    }
    
    func startCapturing() {
        timer = Timer.scheduledTimer(withTimeInterval: settings.screenshotInterval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                try? await self?.captureScreens()
            }
        }
    }
    
    func stopCapturing() {
        timer?.invalidate()
        timer = nil
        Task { @MainActor [weak self] in
            try? await self?.stream?.stopCapture()
            self?.stream = nil
        }
    }
}

// MARK: - SCStreamOutput
extension ScreenCaptureService: SCStreamOutput {
    nonisolated func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
        guard type == .screen,
              let imageBuffer = sampleBuffer.imageBuffer else { return }
        
        // Convert CMSampleBuffer to CGImage
        let ciImage = CIImage(cvImageBuffer: imageBuffer)
        let context = CIContext()
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return }
        
        Task { @MainActor in
            if settings.blurEnabled {
                // Apply blur effect (implementation pending)
            }
            
            // Save screenshot (implementation pending)
        }
    }
}

// MARK: - SCStreamDelegate
extension ScreenCaptureService: SCStreamDelegate {
    nonisolated func stream(_ stream: SCStream, didStopWithError error: Error) {
        print("Stream stopped with error: \(error.localizedDescription)")
    }
}
