import AppKit
import Testing
@testable import MacToolbox

@Suite("Menu-bar icon")
struct MenuBarIconTests {
    @Test("The ghost loads with transparency and keeps its original colors")
    @MainActor
    func ghostResourceLoads() {
        let image = MenuBarIcon.image

        #expect(image.isValid)
        #expect(!image.isTemplate)
        #expect(image.size.width == 22)
        #expect(image.size.height > 0 && image.size.height <= 22)
        #expect(image.representations.contains { representation in
            guard let bitmap = representation as? NSBitmapImageRep else { return false }
            return bitmap.hasAlpha && bitmap.samplesPerPixel == 4
        })
    }
}
