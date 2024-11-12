import AVFoundation
import CoreImage
import CoreImage.CIFilterBuiltins
import SwiftUI

actor VideoProcessor {
    private let settings: CaptureSettings
    private let fileManager: FileManager
    private let context: CIContext
    
    init(settings: CaptureSettings, fileManager: FileManager = .default) {
        self.settings = settings
        self.fileManager = fileManager
        self.context = CIContext()
    }
    
    func createTimelapse(screenshots: [URL], awayPeriods: [AwayPeriod]) async throws -> URL {
        print("📹 Starting timelapse creation with \(screenshots.count) screenshots")
        let outputSize = settings.videoSettings.resolution.size
        let frameRate = settings.videoSettings.frameRate
        
        // Create output URL
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let outputURL = documentsPath.appendingPathComponent("timelapse_\(Date().timeIntervalSince1970).mp4")
        try? FileManager.default.removeItem(at: outputURL)
        
        // Setup writer
        let assetWriter = try AVAssetWriter(url: outputURL, fileType: .mp4)
        
        // Configure video input
        let videoSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: Int(outputSize.width),
            AVVideoHeightKey: Int(outputSize.height)
        ]
        
        let writerInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
        writerInput.expectsMediaDataInRealTime = false
        
        // Create pixel buffer adaptor
        let attributes: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32ARGB,
            kCVPixelBufferWidthKey as String: Int(outputSize.width),
            kCVPixelBufferHeightKey as String: Int(outputSize.height)
        ]
        
        let adaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: writerInput,
            sourcePixelBufferAttributes: attributes
        )
        
        assetWriter.add(writerInput)
        assetWriter.startWriting()
        assetWriter.startSession(atSourceTime: .zero)
        
        // Process frames
        let queue = DispatchQueue(label: "com.app.videowriting")
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            writerInput.requestMediaDataWhenReady(on: queue) {
                autoreleasepool {
                    for (index, screenshotURL) in screenshots.enumerated() {
                        guard let image = CIImage(contentsOf: screenshotURL) else {
                            print("⚠️ Failed to load image at index \(index)")
                            continue
                        }
                        
                        print("🎞 Processing frame \(index + 1)/\(screenshots.count)")
                        
                        // Create frame timing
                        let frameDuration = CMTimeMake(value: 1, timescale: Int32(frameRate))
                        let presentationTime = CMTimeMultiply(frameDuration, multiplier: Int32(index))
                        
                        // Create pixel buffer
                        guard let pool = adaptor.pixelBufferPool else { continue }
                        var pixelBuffer: CVPixelBuffer?
                        CVPixelBufferPoolCreatePixelBuffer(nil, pool, &pixelBuffer)
                        
                        guard let buffer = pixelBuffer else { continue }
                        
                        // Render frame
                        self.context.render(image, to: buffer)
                        
                        // Append frame
                        if !adaptor.append(buffer, withPresentationTime: presentationTime) {
                            continuation.resume(throwing: assetWriter.error ?? NSError())
                            return
                        }
                    }
                    
                    writerInput.markAsFinished()
                    assetWriter.finishWriting {
                        continuation.resume()
                    }
                }
            }
        }
        
        return outputURL
    }
} 