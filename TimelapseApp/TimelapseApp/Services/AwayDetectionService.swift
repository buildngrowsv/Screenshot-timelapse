import Foundation
import AppKit
import SwiftUI

@MainActor
class AwayDetectionService: ObservableObject {
    @Published private(set) var isAway = false
    @Published private(set) var awayStartTime: Date?
    @Published private(set) var awayPeriods: [AwayPeriod] = []
    @Published var showingPrompt = false
    @Published var currentPeriod: AwayPeriod?
    
    private var lastActivityTime = Date()
    private var checkTimer: Timer?
    private var settings: CaptureSettings
    
    private var currentWindow: NSWindow?
    
    init(settings: CaptureSettings) {
        self.settings = settings
        // Defer monitoring start to next run loop
        Task { @MainActor in
            self.startMonitoring()
        }
    }
    
    func updateSettings(_ newSettings: CaptureSettings) {
        self.settings = newSettings
    }
    
    private func startMonitoring() {
        checkTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkActivity()
            }
        }
        
        NSEvent.addGlobalMonitorForEvents(matching: [.mouseMoved, .leftMouseDown, .rightMouseDown, .keyDown]) { [weak self] _ in
            Task { @MainActor in
                self?.updateActivity()
            }
        }
    }
    
    private func updateActivity() {
        lastActivityTime = Date()
        if isAway {
            handleReturn()
        }
    }
    
    private func checkActivity() {
        guard settings.awayDetectionEnabled else { return }
        
        let inactiveTime = Date().timeIntervalSince(lastActivityTime)
        let thresholdSeconds = settings.awayThresholdMinutes * 60
        
        if inactiveTime >= thresholdSeconds && !isAway {
            handleAway()
        }
    }
    
    private func handleAway() {
        isAway = true
        awayStartTime = Date()
    }
    
    private func handleReturn() {
        guard let startTime = awayStartTime else { return }
        print("🔄 Handling return from away period")
        isAway = false
        
        let awayPeriod = AwayPeriod(startTime: startTime, endTime: Date())
        print("📝 Creating new period: \(awayPeriod.id)")
        awayPeriods.append(awayPeriod)
        print("📊 Total periods after append: \(awayPeriods.count)")
        awayStartTime = nil
        currentPeriod = awayPeriod
        
        showAwayPrompt(awayPeriod)
    }
    
    func dismissPrompt() {
        print("❌ Dismissing prompt")
        showingPrompt = false
        currentPeriod = nil
    }
    
    func submitActivity(_ activity: String) {
        print("📝 Submitting activity: \(activity)")
        if let period = currentPeriod,
           let index = awayPeriods.firstIndex(where: { $0.id == period.id }) {
            print("📍 Found period at index: \(index)")
            var updatedPeriod = period
            updatedPeriod.activity = activity
            awayPeriods[index] = updatedPeriod
            print("✅ Updated period activity")
            
            // Force publish the change
            objectWillChange.send()
            
            // Debug print current periods
            print("📊 Current away periods: \(awayPeriods.count)")
            awayPeriods.forEach { period in
                print("   - \(period.id): \(period.activity)")
            }
        } else {
            print("⚠️ Could not find period in array")
        }
        dismissPrompt()
    }
    
    private func showAwayPrompt(_ period: AwayPeriod) {
        print("🪟 Showing away prompt for period: \(period.id)")
        currentPeriod = period
        
        if let existing = currentWindow {
            existing.close()
            currentWindow = nil
        }
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 200),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        
        window.title = "Welcome Back!"
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.isReleasedWhenClosed = true
        
        let promptView = AwayPromptView(
            awayPeriod: period,
            onSubmit: { [weak self] activity in
                self?.submitActivity(activity)
                window.close()
            },
            onCancel: { [weak self] in
                self?.dismissPrompt()
                window.close()
            }
        )
        
        window.contentView = NSHostingView(rootView: promptView)
        window.center()
        window.makeKeyAndOrderFront(nil)
        
        currentWindow = window
    }
    
    // Add this public method for testing
    func testAwayPrompt() {
        let testPeriod = AwayPeriod(startTime: Date().addingTimeInterval(-600), endTime: Date())
        showAwayPrompt(testPeriod)
    }
} 