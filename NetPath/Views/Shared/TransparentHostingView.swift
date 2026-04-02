import AppKit
import SwiftUI

/// NSHostingView subclass that applies a CAShapeLayer mask on every layout pass
/// and keeps an associated shadow layer sized correctly.
final class MaskedHostingView<Content: View>: NSHostingView<Content> {
    private let cornerRadius: CGFloat
    private let maskLayer = CAShapeLayer()

    /// Optional shadow layer to resize on layout (set by the panel setup code)
    var shadowLayer: CALayer?

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
        let b = bounds
        maskLayer.path = CGPath(roundedRect: b,
                                cornerWidth: cornerRadius,
                                cornerHeight: cornerRadius,
                                transform: nil)
        maskLayer.frame = b

        // Keep shadow layer matched to the parent effect view's bounds
        if let shadow = shadowLayer, let parentBounds = superview?.bounds {
            shadow.frame = parentBounds
            shadow.shadowPath = CGPath(roundedRect: parentBounds,
                                        cornerWidth: cornerRadius,
                                        cornerHeight: cornerRadius,
                                        transform: nil)
        }
    }
}
