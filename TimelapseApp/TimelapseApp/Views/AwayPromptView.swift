import SwiftUI

struct AwayPromptView: View {
    let awayPeriod: AwayPeriod
    let onSubmit: (String) -> Void
    let onCancel: () -> Void
    
    @State private var activity: String = ""
    
    var body: some View {
        VStack(spacing: 16) {
            Text("You were away for \(formatDuration(awayPeriod.duration))")
                .font(.headline)
            
            Text("What were you doing?")
                .font(.subheadline)
            
            TextEditor(text: $activity)
                .frame(height: 80)
                .border(Color.gray.opacity(0.2))
            
            HStack {
                Button("Cancel") {
                    print("❌ Cancel button clicked")
                    onCancel()
                }
                
                Button("Submit") {
                    print("✅ Submit button clicked")
                    onSubmit(activity)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(width: 400)
    }
    
    private func formatDuration(_ interval: TimeInterval) -> String {
        let minutes = Int(interval / 60)
        if minutes < 60 {
            return "\(minutes) minutes"
        } else {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            return "\(hours) hours \(remainingMinutes) minutes"
        }
    }
} 