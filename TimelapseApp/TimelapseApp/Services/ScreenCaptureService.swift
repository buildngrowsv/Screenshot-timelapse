import SwiftUI
import ScreenCaptureKit
import CoreImage
import CoreMedia

@MainActor
class ScreenCaptureService: NSObject, ObservableObject, SCStreamDelegate, SCStreamOutput {
    private var stream: SCStream?
    private var streamConfiguration: SCStreamConfiguration?
    
    // Private actor-isolated capture status
    private var isCapturing: Bool = false
    
    // Public interface for checking capture status
    nonisolated private func checkCaptureStatus() async -> Bool {
        await withCheckedContinuation { continuation in
            Task { @MainActor in
                continuation.resume(returning: isCapturing)
            }
        }
    }
    
    // Public interface for setting capture status
    nonisolated private func setCaptureStatus(_ newValue: Bool) async {
        await withCheckedContinuation { continuation in
            Task { @MainActor in
                isCapturing = newValue
                continuation.resume()
            }
        }
    }
    
    func captureScreenshot() async throws {
        guard !await checkCaptureStatus() else { return }
        try await captureScreens()
    }
    
    private func captureScreens() async throws {
        guard let display = await SCShareableContent.current.displays.first else {
            throw NSError(domain: "ScreenCapture", code: 1, userInfo: [NSLocalizedDescriptionKey: "No display found"])
        }
        
        let configuration = SCStreamConfiguration()
        configuration.width = display.width
        configuration.height = display.height
        configuration.showsCursor = false
        self.streamConfiguration = configuration
        
        let filter = SCContentFilter(display: display, excludingWindows: [])
        self.stream = SCStream(filter: filter, configuration: configuration, delegate: self)
        
        try await stream?.addStreamOutput(self as SCStreamOutput, type: .screen, sampleHandlerQueue: .main)
        isCapturing = true
        try await stream?.startCapture()
    }
    
    nonisolated func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
        Task {
            guard await checkCaptureStatus() else { return }
            
            guard type == .screen,
                  let imageBuffer = sampleBuffer.imageBuffer else { 
                print("Waiting for valid image buffer...")
                return 
            }
            
            let ciImage = CIImage(cvImageBuffer: imageBuffer)
            let context = CIContext()
            guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { 
                print("Failed to create CGImage")
                return 
            }
            
            Task { @MainActor in
                // Create NSImage from CGImage
                let image = NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
                
                // Save to Documents/TimelapseScreenshots
                if let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                    let screenshotsPath = documentsPath.appendingPathComponent("TimelapseScreenshots")
                    
                    try? FileManager.default.createDirectory(at: screenshotsPath, 
                                                           withIntermediateDirectories: true)
                    
                    let timestamp = ISO8601DateFormatter().string(from: Date())
                    let imageUrl = screenshotsPath.appendingPathComponent("screenshot_\(timestamp).png")
                    
                    print("Attempting to save screenshot to: \(imageUrl.path)")
                    
                    if let imageData = image.tiffRepresentation,
                       let bitmapImage = NSBitmapImageRep(data: imageData),
                       let pngData = bitmapImage.representation(using: .png, properties: [:]) {
                        do {
                            try pngData.write(to: imageUrl)
                            print("Successfully saved screenshot to: \(imageUrl.path)")
                            
                            // Stop capturing after successful save
                            await setCaptureStatus(false)
                            try? await self.stream?.stopCapture()
                            self.stream = nil
                        } catch {
                            print("Failed to write screenshot: \(error)")
                        }
                    } else {
                        print("Failed to convert image to PNG data")
                    }
                }
            }
        }
    }
    
    nonisolated func stream(_ stream: SCStream, didStopWithError error: Error) {
        Task { @MainActor in
            isCapturing = false
            self.stream = nil
            print("Stream stopped with error: \(error)")
        }
    }
} 