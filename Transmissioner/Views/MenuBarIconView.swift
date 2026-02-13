import AppKit
import SwiftUI

struct MenuBarIconView: View {
    @ObservedObject var viewModelStore: ServiceViewModelStore

    var body: some View {
        Image(nsImage: composedIcon)
    }

    private var composedIcon: NSImage {
        let baseImage = NSImage(named: "MenuBarIcon") ?? NSImage()
        let size = baseImage.size.width > 0 ? baseImage.size : NSSize(width: 18, height: 18)

        let composed = NSImage(size: size, flipped: false) { rect in
            baseImage.draw(in: rect)

            // Draw indicator dot if needed
            if let color = self.indicatorNSColor {
                let dotSize: CGFloat = 6
                let dotRect = NSRect(
                    x: rect.maxX - dotSize + 2,
                    y: rect.maxY - dotSize + 2,
                    width: dotSize,
                    height: dotSize
                )
                color.setFill()
                NSBezierPath(ovalIn: dotRect).fill()
            }

            return true
        }

        composed.isTemplate = false
        return composed
    }

    private var indicatorNSColor: NSColor? {
        if viewModelStore.hasActiveDownloads {
            return .systemGreen
        } else if viewModelStore.hasErrors {
            return .systemRed
        } else if viewModelStore.hasOfflineServices {
            return .systemOrange
        }
        return .systemBlue // Test color - remove later
    }
}
