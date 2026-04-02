import AppKit

/// Applies a rounded-rectangle mask to an NSView's layer, updating on resize.
/// Clips NSHostingView's opaque background at the corners of borderless panels.
@MainActor
final class HostingViewLayoutObserver: NSObject {
    private weak var hostingView: NSView?
    private let cornerRadius: CGFloat
    nonisolated(unsafe) private var boundsObservation: Any?

    init(hostingView: NSView, cornerRadius: CGFloat) {
        self.hostingView = hostingView
        self.cornerRadius = cornerRadius
        super.init()

        hostingView.postsFrameChangedNotifications = true
        boundsObservation = NotificationCenter.default.addObserver(
            forName: NSView.frameDidChangeNotification,
            object: hostingView,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.updateMask()
            }
        }

        updateMask()
    }

    deinit {
        if let obs = boundsObservation {
            NotificationCenter.default.removeObserver(obs)
        }
    }

    private func updateMask() {
        guard let view = hostingView else { return }
        view.wantsLayer = true
        guard let layer = view.layer else { return }

        let maskLayer: CAShapeLayer
        if let existing = layer.mask as? CAShapeLayer {
            maskLayer = existing
        } else {
            maskLayer = CAShapeLayer()
            layer.mask = maskLayer
        }

        let bounds = view.bounds
        let path = CGPath(roundedRect: bounds,
                          cornerWidth: cornerRadius,
                          cornerHeight: cornerRadius,
                          transform: nil)
        maskLayer.path = path
        maskLayer.frame = bounds
    }
}
