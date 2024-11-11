import Foundation
import ScreenCaptureKit
import AppKit
import CoreImage
import CoreMedia
import CoreImage.CIFilterBuiltins

@MainActor
class ScreenCaptureService: NSObject, ObservableObject {
    // Published properties for display management
    @Published private(set) var availableDisplays: [SCDisplay] = []
    @Published var selectedDisplays: Set<SCDisplay> = []
    
    // Add to class properties
    @Published var settings = CaptureSettings()
    
    // Capture a screenshot
    func captureScreenshot() async throws {
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
        
        // Get all available windows
        let content = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<SCShareableContent, Error>) in
            SCShareableContent.getExcludingDesktopWindows(false, onScreenWindowsOnly: true) { content, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let content = content {
                    continuation.resume(returning: content)
                } else {
                    continuation.resume(throwing: NSError(domain: "ScreenCapture", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to get shareable content"]))
                }
            }
        }
        let displays = Array(selectedDisplays)
        
        // Configure the stream with combined display bounds
        let configuration = SCStreamConfiguration()
        let displayBounds = calculateCombinedDisplayBounds()
        configuration.width = Int(displayBounds.width)
        configuration.height = Int(displayBounds.height)
        configuration.showsCursor = false
        
        // Create content filter
        let filter: SCContentFilter
        if displays.count == 1 {
            // Single display case
            filter = SCContentFilter(
                display: displays[0],
                excludingWindows: []
            )
        } else {
            // Multiple display case - get all windows for selected displays
            let windowsForSelectedDisplays = content.windows.filter { window in
                // Check if the window belongs to any of our selected displays
                return selectedDisplays.contains { display in
                    // A window belongs to a display if its frame intersects with the display's frame
                    window.frame.intersects(display.frame)
                }
            }
            
            // Create filter with primary display and include all relevant windows
            filter = SCContentFilter(
                display: displays[0],
                including: windowsForSelectedDisplays
            )
        }
        
        // Use SCScreenshotManager to capture the image
        let cgImage = try await SCScreenshotManager.captureImage(
            contentFilter: filter,
            configuration: configuration
        )
        
        // Process and save the image
        Task { @MainActor in
            let processedImage = processImage(cgImage)
            
            if let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                let screenshotsPath = documentsPath.appendingPathComponent("TimelapseScreenshots")
                let timestamp = ISO8601DateFormatter().string(from: Date())
                let imageUrl = screenshotsPath.appendingPathComponent("screenshot_\(timestamp).png")
                
                if let imageData = processedImage.tiffRepresentation,
                   let bitmapImage = NSBitmapImageRep(data: imageData),
                   let pngData = bitmapImage.representation(using: .png, properties: [:]) {
                    do {
                        try pngData.write(to: imageUrl)
                        print("Successfully saved screenshot to: \(imageUrl.path)")
                    } catch {
                        print("Failed to write screenshot: \(error)")
                    }
                }
            }
        }
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
    
    // Add this method after image capture but before saving
    private func processImage(_ image: CGImage) -> NSImage {
        var processedImage = CIImage(cgImage: image)
        let context = CIContext()
        
        // Apply blur if enabled
        if settings.blurEnabled {
            let blur = CIFilter.gaussianBlur()
            blur.inputImage = processedImage
            blur.radius = settings.blurRadius
            if let blurredImage = blur.outputImage {
                processedImage = blurredImage
            }
        }
        
        // Resize if needed
        if let dimensions = settings.resolution.dimensions {
            let scaleX = Double(dimensions.width) / Double(processedImage.extent.width)
            let scaleY = Double(dimensions.height) / Double(processedImage.extent.height)
            let scale = min(scaleX, scaleY) // Maintain aspect ratio
            
            let scaleTransform = CIFilter.lanczosScaleTransform()
            scaleTransform.inputImage = processedImage
            scaleTransform.scale = Float(scale)
            scaleTransform.aspectRatio = 1.0
            
            if let resizedImage = scaleTransform.outputImage {
                processedImage = resizedImage
            }
        }
        
        // Convert back to CGImage
        if let finalCGImage = context.createCGImage(processedImage, from: processedImage.extent) {
            return NSImage(cgImage: finalCGImage, size: NSSize(width: processedImage.extent.width, height: processedImage.extent.height))
        }
        
        // Return original if processing failed
        return NSImage(cgImage: image, size: NSSize(width: image.width, height: image.height))
    }
} 