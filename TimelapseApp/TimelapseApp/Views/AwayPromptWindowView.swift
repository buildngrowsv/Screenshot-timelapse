import SwiftUI
import AppKit

struct AwayPromptWindowView: View {
    @ObservedObject var awayDetectionService: AwayDetectionService
    
    var body: some View {
        if let period = awayDetectionService.currentPeriod {
            AwayPromptView(
                awayPeriod: period,
                onSubmit: { activity in
                    print("🔄 AwayPromptView onSubmit called")
                    awayDetectionService.submitActivity(activity)
                },
                onCancel: {
                    print("❌ AwayPromptView cancel called")
                    awayDetectionService.dismissPrompt()
                }
            )
            .onDisappear {
                print("👋 AwayPromptView disappeared")
            }
        }
    }
    
    func showInWindow() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 200),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        
        window.title = "Welcome Back!"
        window.contentView = NSHostingView(rootView: self)
        window.center()
        window.makeKeyAndOrderFront(nil)
        window.isReleasedWhenClosed = true
        window.level = .floating
    }
} 
