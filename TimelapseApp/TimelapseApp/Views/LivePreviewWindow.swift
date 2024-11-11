import SwiftUI
import ScreenCaptureKit

struct LivePreviewWindow: View {
    @ObservedObject var screenshotManager: ScreenshotManager
    @State private var previewImage: NSImage?
    
    var body: some View {
        VStack {
            if let previewImage {
                Image(nsImage: previewImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(minWidth: 640, minHeight: 360)
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(minWidth: 640, minHeight: 360)
            }
        }
        .padding()
        .onChange(of: screenshotManager.settings) { _ in
            Task {
                await updatePreview()
            }
        }
        .task {
            await updatePreview()
        }
    }
    
    private func updatePreview() async {
        guard let selectedDisplay = screenshotManager.selectedDisplays.first else { return }
        
        do {
            let filter = SCContentFilter(display: selectedDisplay, excludingWindows: [])
            let config = SCStreamConfiguration()
            
            // Use settings resolution
            if let dimensions = screenshotManager.settings.resolution.dimensions {
                config.width = dimensions.width
                config.height = dimensions.height
            } else {
                config.width = Int(selectedDisplay.width)
                config.height = Int(selectedDisplay.height)
            }
            
            config.showsCursor = false
            
            if let cgImage = try? await SCScreenshotManager.captureImage(
                contentFilter: filter,
                configuration: config
            ) {
                // Apply blur if enabled
                if screenshotManager.settings.blurEnabled {
                    let ciImage = CIImage(cgImage: cgImage)
                    let context = CIContext()
                    
                    let blur = CIFilter.gaussianBlur()
                    blur.inputImage = ciImage
                    blur.radius = screenshotManager.settings.blurRadius
                    
                    if let blurredImage = blur.outputImage,
                       let blurredCGImage = context.createCGImage(blurredImage, from: blurredImage.extent) {
                        await MainActor.run {
                            self.previewImage = NSImage(cgImage: blurredCGImage, size: NSSize(width: blurredImage.extent.width, height: blurredImage.extent.height))
                        }
                        return
                    }
                }
                
                // If no blur or blur failed, show original image
                await MainActor.run {
                    self.previewImage = NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
                }
            }
        } catch {
            print("Preview capture error: \(error)")
        }
    }
} 