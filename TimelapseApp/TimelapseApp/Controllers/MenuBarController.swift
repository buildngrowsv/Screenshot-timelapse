import Foundation
import SwiftUI

@MainActor
class MenuBarController: ObservableObject {
    private let screenCaptureService: ScreenCaptureService
    private let fileManager = FileManager.default
    
    init() {
        self.screenCaptureService = ScreenCaptureService()
        createScreenshotsDirectory()
    }
    
    private func createScreenshotsDirectory() {
        guard let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let screenshotsPath = documentsPath.appendingPathComponent("TimelapseScreenshots")
        
        do {
            try fileManager.createDirectory(at: screenshotsPath, withIntermediateDirectories: true)
        } catch {
            print("Error creating screenshots directory: \(error)")
        }
    }
    
    func captureScreenshot() {
        Task {
            try? await screenCaptureService.captureScreenshot()
        }
    }
} 