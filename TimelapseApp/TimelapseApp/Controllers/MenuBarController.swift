import Foundation
import SwiftUI

@MainActor
class MenuBarController: ObservableObject {
    private let screenCaptureService: ScreenCaptureService
    let screenshotManager: ScreenshotManager
    private let fileManager = FileManager.default
    
    init() {
        self.screenCaptureService = ScreenCaptureService()
        self.screenshotManager = ScreenshotManager(screenCaptureService: screenCaptureService)
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
} 