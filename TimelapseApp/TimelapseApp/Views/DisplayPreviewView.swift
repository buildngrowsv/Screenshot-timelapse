import SwiftUI
import ScreenCaptureKit

struct DisplayPreviewView: View {
    let display: SCDisplay
    @State private var previewImage: NSImage?
    
    var body: some View {
        HStack(spacing: 8) {
            if let previewImage {
                Image(nsImage: previewImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 80, height: 45)  // 16:9 aspect ratio
                    .cornerRadius(4)
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 80, height: 45)
                    .cornerRadius(4)
            }
            
            Text("Display \(display.displayID)")
                .font(.caption)
        }
        .task {
            await updatePreview()
        }
    }
    
    private func updatePreview() async {
        do {
            let filter = SCContentFilter(display: display, excludingWindows: [])
            let config = SCStreamConfiguration()
            config.width = 160  // Double the display size for retina
            config.height = 90
            config.showsCursor = false
            
            if let cgImage = try? await SCScreenshotManager.captureImage(
                contentFilter: filter,
                configuration: config
            ) {
                await MainActor.run {
                    self.previewImage = NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
                }
            }
        } catch {
            print("Preview capture error: \(error)")
        }
    }
} 