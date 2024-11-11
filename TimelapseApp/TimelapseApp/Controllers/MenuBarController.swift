import Foundation
import SwiftUI

@MainActor
class MenuBarController: ObservableObject {
    let screenshotManager: ScreenshotManager
    
    init() {
        let screenCaptureService = ScreenCaptureService()
        self.screenshotManager = ScreenshotManager(screenCaptureService: screenCaptureService)
        
        // Move display fetching to after initialization
        Task {
            await screenshotManager.fetchDisplays()
        }
    }
} 