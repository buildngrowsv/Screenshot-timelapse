import SwiftUI

struct RadioButton<Content: View>: View {
    let selected: Binding<Bool>
    let content: () -> Content
    
    init(selected: Binding<Bool>, @ViewBuilder content: @escaping () -> Content) {
        self.selected = selected
        self.content = content
    }
    
    var body: some View {
        Button(action: {
            selected.wrappedValue = true
        }) {
            HStack(spacing: 8) {
                Circle()
                    .stroke(Color.blue, lineWidth: 1)
                    .frame(width: 16, height: 16)
                    .overlay(
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 10, height: 10)
                            .opacity(selected.wrappedValue ? 1 : 0)
                    )
                
                content()
            }
        }
        .buttonStyle(.plain)
    }
} 