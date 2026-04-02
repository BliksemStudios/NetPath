import AppKit
import SwiftUI

/// NSHostingView subclass that applies a CAShapeLayer mask on every layout pass.
/// This clips the hosting view's opaque background at rounded corners.
final class MaskedHostingView<Content: View>: NSHostingView<Content> {
    private let cornerRadius: CGFloat
    private let maskLayer = CAShapeLayer()

    init(rootView: Content, cornerRadius: CGFloat) {
        self.cornerRadius = cornerRadius
        super.init(rootView: rootView)
        wantsLayer = true
        layer?.mask = maskLayer
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    required init(rootView: Content) {
        self.cornerRadius = 12
        super.init(rootView: rootView)
        wantsLayer = true
        layer?.mask = maskLayer
    }

    override func layout() {
        super.layout()
        maskLayer.path = CGPath(
            roundedRect: bounds,
            cornerWidth: cornerRadius,
            cornerHeight: cornerRadius,
            transform: nil
        )
        maskLayer.frame = bounds
    }
}
