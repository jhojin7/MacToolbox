import Testing
@testable import MacToolbox

@Suite("Display effects state")
@MainActor
struct DisplayEffectsControllerTests {
    @Test("System refresh updates the Night Shift check without a success message")
    func refreshUpdatesObservedState() {
        let system = FakeDisplayEffects()
        let controller = DisplayEffectsController(backend: system.backend)
        controller.setNightShiftEnabled(true)
        #expect(controller.nightShiftEnabled)
        #expect(controller.errorMessage == nil)

        system.nightShiftEnabled = false
        controller.refresh()
        #expect(!controller.nightShiftEnabled)
        #expect(controller.errorMessage == nil)

        system.nightShiftEnabled = true
        controller.refresh()
        #expect(controller.nightShiftEnabled)
        #expect(controller.errorMessage == nil)
    }

    @Test("A successful request displays the system readback, not the requested value")
    func successfulRequestUsesReadback() {
        let system = FakeDisplayEffects()
        system.applyNightShiftRequest = false
        let controller = DisplayEffectsController(backend: system.backend)

        controller.setNightShiftEnabled(true)

        #expect(!controller.nightShiftEnabled)
        #expect(controller.errorMessage == nil)
    }

    @Test("A failed request preserves the observed state and reports the error")
    func failedRequestReportsError() {
        let system = FakeDisplayEffects()
        system.nightShiftEnabled = true
        system.nightShiftRequestSucceeds = false
        let controller = DisplayEffectsController(backend: system.backend)

        controller.setNightShiftEnabled(false)

        #expect(controller.nightShiftEnabled)
        #expect(controller.errorMessage == "Night Shift could not be changed")
        controller.refresh()
        #expect(controller.errorMessage == "Night Shift could not be changed")

        system.nightShiftRequestSucceeds = true
        controller.setNightShiftEnabled(false)
        #expect(!controller.nightShiftEnabled)
        #expect(controller.errorMessage == nil)
    }

    @Test("Color Filters reports failures and clears the error after success")
    func colorFilterReportsOnlyErrors() {
        let system = FakeDisplayEffects()
        let controller = DisplayEffectsController(backend: system.backend)
        system.colorFilterRequestSucceeds = false
        controller.setColorFilterEnabled(true)
        #expect(controller.errorMessage == "Color Filters are unavailable on this macOS version")

        system.colorFilterRequestSucceeds = true
        controller.setColorFilterEnabled(true)
        #expect(controller.colorFilterEnabled)
        #expect(controller.errorMessage == nil)
    }
}

@MainActor
private final class FakeDisplayEffects {
    var colorFilterRequestSucceeds = true
    var nightShiftEnabled = false
    var nightShiftRequestSucceeds = true
    var applyNightShiftRequest = true

    var backend: DisplayEffectsBackend {
        DisplayEffectsBackend(
            colorFilterIsAvailable: { true },
            colorFilterIsEnabled: { false },
            setColorFilterEnabled: { _ in self.colorFilterRequestSucceeds },
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
