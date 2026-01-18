import AppKit
import SwiftUI

struct WindowAccessor: NSViewRepresentable {
    let minSize: CGSize
    let initialSize: CGSize
    let onResize: (CGSize) -> Void

    func makeNSView(context: Context) -> NSView {
        NSView()
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            guard let window = nsView.window else { return }
            if context.coordinator.window !== window {
                context.coordinator.attach(
                    to: window,
                    minSize: minSize,
                    initialSize: initialSize,
                    onResize: onResize
                )
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    final class Coordinator {
        weak var window: NSWindow?
        private var observers: [NSObjectProtocol] = []

        func attach(to window: NSWindow, minSize: CGSize, initialSize: CGSize, onResize: @escaping (CGSize) -> Void) {
            detach()
            self.window = window
            window.styleMask.insert(.resizable)
            window.minSize = NSSize(width: minSize.width, height: minSize.height)
            window.setContentSize(initialSize)

            let center = NotificationCenter.default
            observers.append(center.addObserver(
                forName: NSWindow.didResizeNotification,
                object: window,
                queue: .main
            ) { [weak window] _ in
                guard let window else { return }
                let size = window.contentView?.bounds.size ?? window.frame.size
                onResize(size)
            })

            observers.append(center.addObserver(
                forName: NSWindow.willCloseNotification,
                object: window,
                queue: .main
            ) { [weak window] _ in
                guard let window else { return }
                let size = window.contentView?.bounds.size ?? window.frame.size
                onResize(size)
            })

            // MenuBarExtra can override size shortly after open; re-apply after a short delay.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak window] in
                guard let window else { return }
                window.setContentSize(initialSize)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak window] in
                guard let window else { return }
                window.setContentSize(initialSize)
            }

        }

        private func detach() {
            let center = NotificationCenter.default
            for observer in observers {
                center.removeObserver(observer)
            }
            observers.removeAll()
        }

        deinit {
            detach()
        }
    }
}
