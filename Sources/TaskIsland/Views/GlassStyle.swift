import SwiftUI

extension View {
    @ViewBuilder
    func taskIslandGlass<S: Shape>(in shape: S) -> some View {
        if #available(macOS 26.0, *) {
            glassEffect(.regular.interactive(true), in: shape)
        } else {
            background(.ultraThinMaterial, in: shape)
        }
    }
}
