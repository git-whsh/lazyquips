import AppKit
import SwiftUI

final class HostedWindowController<Content: View>: NSWindowController, NSWindowDelegate {
    private let onClose: () -> Void

    init(
        title: String,
        size: NSSize,
        styleMask: NSWindow.StyleMask = [.titled, .closable],
        minSize: NSSize? = nil,
        rootView: Content,
        onClose: @escaping () -> Void
    ) {
        self.onClose = onClose

        let window = NSWindow(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: styleMask,
            backing: .buffered,
            defer: false
        )
        window.title = title
        window.center()
        window.isReleasedWhenClosed = false
        if let minSize {
            window.minSize = minSize
        }
        window.contentViewController = NSHostingController(rootView: rootView)

        super.init(window: window)

        window.delegate = self
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    func windowWillClose(_ notification: Notification) {
        onClose()
    }
}
