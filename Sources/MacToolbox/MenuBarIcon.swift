import AppKit

@MainActor
enum MenuBarIcon {
    static let image: NSImage = {
        // Packaged apps carry the image in Contents/Resources; swift run uses
        // the SwiftPM resource bundle instead.
        let url = Bundle.main.url(forResource: "MenuBarGhost", withExtension: "png")
            ?? Bundle.module.url(forResource: "MenuBarGhost", withExtension: "png")
        guard let url, let image = NSImage(contentsOf: url) else {
            return NSImage(systemSymbolName: "wrench.and.screwdriver",
                           accessibilityDescription: "Mac Toolbox") ?? NSImage()
        }

        let width: CGFloat = 22
        image.size = NSSize(width: width, height: width * image.size.height / image.size.width)
        image.isTemplate = false
        return image
    }()
}
