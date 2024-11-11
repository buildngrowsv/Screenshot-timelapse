import Foundation
import ScreenCaptureKit
import AppKit
import CoreImage
import CoreMedia

@MainActor
class ScreenCaptureService: NSObject, ObservableObject, SCStreamDelegate, SCStreamOutput {
    private var stream: SCStream?
    private var streamConfiguration: SCStreamConfiguration?
    private var isCapturing = false
    
    // Published properties for display management
    @Published private(set) var availableDisplays: [SCDisplay] = []
    @Published var selectedDisplays: Set<SCDisplay> = []
    
    // Capture a screenshot
    func captureScreenshot() async throws {
        guard !isCapturing else { return }
        try await captureScreens()
    }
    
    // Capture screens based on selected displays
    private func captureScreens() async throws {
        guard !selectedDisplays.isEmpty else {
            throw NSError(
                domain: "ScreenCapture",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "No displays selected"]
            )
        }
        
        // Create filter based on first selected display
        guard let display = selectedDisplays.first else { return }
        
        // Create content filter with simple display filter
        let filter = SCContentFilter(
            display: display,
            excludingWindows: []  // This captures the entire display without excluding any windows
        )
        
        // Configure the stream
        let configuration = SCStreamConfiguration()
        configuration.width = Int(display.width)
        configuration.height = Int(display.height)
        configuration.showsCursor = false
        self.streamConfiguration = configuration
        
        // Create and configure stream
        self.stream = SCStream(
            filter: filter,
            configuration: configuration,
            delegate: self
        )
        
        // Add output and start capture
        try await stream?.addStreamOutput(
            self,
            type: .screen,
            sampleHandlerQueue: DispatchQueue.main
        )
        
        isCapturing = true
        try await stream?.startCapture()
    }
    
    // Calculate the combined bounds of selected displays
    private func calculateCombinedDisplayBounds() -> CGRect {
        selectedDisplays.reduce(CGRect.null) { result, display in
            let rect = CGRect(
                x: display.frame.origin.x,
                y: display.frame.origin.y,
                width: display.frame.width,
                height: display.frame.height
            )
            return result.union(rect)
        }
    }
    
    // Fetch available displays
    func fetchAvailableDisplays() async {
        do {
            let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: false)
            availableDisplays = content.displays
            
            // Select the first display by default if none are selected
            if selectedDisplays.isEmpty, let firstDisplay = availableDisplays.first {
                selectedDisplays.insert(firstDisplay)
            }
        } catch {
            print("Error fetching displays: \(error)")
        }
    }
    
    // Stream output handler
    nonisolated func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
        guard type == .screen,
              let imageBuffer = sampleBuffer.imageBuffer else { return }
        
        // Create CIImage and CGImage from the image buffer
        let ciImage = CIImage(cvImageBuffer: imageBuffer)
        let context = CIContext()
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return }
        
        // Save the image on the main thread
        Task { @MainActor in
            let image = NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
            
            if let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                let screenshotsPath = documentsPath.appendingPathComponent("TimelapseScreenshots")
                let timestamp = ISO8601DateFormatter().string(from: Date())
                let imageUrl = screenshotsPath.appendingPathComponent("screenshot_\(timestamp).png")
                
                if let imageData = image.tiffRepresentation,
                   let bitmapImage = NSBitmapImageRep(data: imageData),
                   let pngData = bitmapImage.representation(using: .png, properties: [:]) {
                    do {
                        try pngData.write(to: imageUrl)
                        print("Successfully saved screenshot to: \(imageUrl.path)")
                        
                        // Stop capturing after saving the screenshot
                        if isCapturing {
                            isCapturing = false
                            try? await self.stream?.stopCapture()
                            self.stream = nil
                        }
                    } catch {
                        print("Failed to write screenshot: \(error)")
                    }
                }
            }
        }
    }
    
    // Handle stream errors
    nonisolated func stream(_ stream: SCStream, didStopWithError error: Error) {
        Task { @MainActor in
            isCapturing = false
            self.stream = nil
            print("Stream stopped with error: \(error)")
        }
    }
} 