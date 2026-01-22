import SwiftUI

struct LiquidGlassOverlay: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(.separator, lineWidth: 1)
            )
            .shadow(radius: 10)
    }
}

extension View {
    func liquidGlassOverlay() -> some View {
        modifier(LiquidGlassOverlay())
    }
}
