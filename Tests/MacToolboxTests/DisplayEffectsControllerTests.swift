import Testing
@testable import MacToolbox

@Suite("Display effects state")
@MainActor
struct DisplayEffectsControllerTests {
    @Test("System refresh updates both the Night Shift check and message")
    func refreshKeepsMessageInSync() {
        let system = FakeDisplayEffects()
        let controller = DisplayEffectsController(backend: system.backend)
        controller.setNightShiftEnabled(true)
        #expect(controller.nightShiftEnabled)
        #expect(controller.status == "Night Shift enabled")

        system.nightShiftEnabled = false
        controller.refresh()
        #expect(!controller.nightShiftEnabled)
        #expect(controller.status == "Night Shift disabled")

        system.nightShiftEnabled = true
        controller.refresh()
        #expect(controller.nightShiftEnabled)
        #expect(controller.status == "Night Shift enabled")
    }

    @Test("A successful request displays the system readback, not the requested value")
    func successfulRequestUsesReadback() {
        let system = FakeDisplayEffects()
        system.applyNightShiftRequest = false
        let controller = DisplayEffectsController(backend: system.backend)

        controller.setNightShiftEnabled(true)

        #expect(!controller.nightShiftEnabled)
        #expect(controller.status == "Night Shift disabled")
    }

    @Test("A failed request preserves the observed state and reports the error")
    func failedRequestReportsError() {
        let system = FakeDisplayEffects()
        system.nightShiftEnabled = true
        system.nightShiftRequestSucceeds = false
        let controller = DisplayEffectsController(backend: system.backend)

        controller.setNightShiftEnabled(false)

        #expect(controller.nightShiftEnabled)
        #expect(controller.status == "Night Shift could not be changed")
        controller.refresh()
        #expect(controller.status == "Night Shift could not be changed")
    }

    @Test("Refreshing Night Shift does not replace an unrelated Color Filters message")
    func refreshPreservesColorFilterMessage() {
        let system = FakeDisplayEffects()
        let controller = DisplayEffectsController(backend: system.backend)
        controller.setColorFilterEnabled(true)

        system.nightShiftEnabled = true
        controller.refresh()

        #expect(controller.nightShiftEnabled)
        #expect(controller.status == "Color Filters enabled")
    }
}

@MainActor
private final class FakeDisplayEffects {
    var nightShiftEnabled = false
    var nightShiftRequestSucceeds = true
    var applyNightShiftRequest = true

    var backend: DisplayEffectsBackend {
        DisplayEffectsBackend(
            colorFilterIsAvailable: { true },
            colorFilterIsEnabled: { false },
            setColorFilterEnabled: { _ in true },
            nightShiftIsAvailable: { true },
            nightShiftIsEnabled: { self.nightShiftEnabled },
            setNightShiftEnabled: { enabled in
                guard self.nightShiftRequestSucceeds else { return false }
                if self.applyNightShiftRequest {
                    self.nightShiftEnabled = enabled
                }
                return true
            },
            startNightShiftStatusNotifications: { false }
        )
    }
}
