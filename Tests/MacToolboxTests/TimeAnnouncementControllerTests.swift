import Foundation
import Testing
@testable import MacToolbox

@Suite("Time announcements")
@MainActor
struct TimeAnnouncementControllerTests {
    @Test("Toggling preserves interval, nested voice options, and unknown settings")
    func preservesSettings() {
        let system = FakeTimeAnnouncements()
        let original = system.preferences
        let controller = TimeAnnouncementController(backend: system.backend)
        #expect(controller.isEnabled)

        for enabled in [false, true] {
            controller.setEnabled(enabled)
            #expect(controller.isEnabled == enabled)
            var expected = original
            expected["TimeAnnouncementsEnabled"] = enabled
            #expect(NSDictionary(dictionary: system.preferences).isEqual(to: expected))
            #expect(controller.errorMessage == nil)
        }
    }

    @Test("Missing preferences are off and enabling creates only the enabled key")
    func missingPreferences() {
        let system = FakeTimeAnnouncements()
        system.preferences = [:]
        let controller = TimeAnnouncementController(backend: system.backend)
        #expect(!controller.isEnabled)
        controller.setEnabled(true)
        #expect(controller.isEnabled)
        #expect(system.preferences.count == 1)
    }

    @Test("Refresh and writes use current system settings, including external changes")
    func externalChanges() {
        let system = FakeTimeAnnouncements()
        let controller = TimeAnnouncementController(backend: system.backend)
        system.preferences["TimeAnnouncementsEnabled"] = false
        system.preferences["TimeAnnouncementsIntervalIdentifier"] = "EveryHalfHourInterval"
        controller.refresh()
        #expect(!controller.isEnabled)
        controller.setEnabled(true)
        #expect(system.preferences["TimeAnnouncementsIntervalIdentifier"] as? String == "EveryHalfHourInterval")
    }

    @Test("Write failures keep the observed checkmark and a successful retry clears errors")
    func writeFailure() {
        let system = FakeTimeAnnouncements()
        let controller = TimeAnnouncementController(backend: system.backend)
        system.writeFails = true
        controller.setEnabled(false)
        #expect(controller.isEnabled)
        #expect(controller.errorMessage != nil)
        system.writeFails = false
        controller.setEnabled(false)
        #expect(!controller.isEnabled)
        #expect(controller.errorMessage == nil)
    }

    @Test("An ignored write reports failure instead of displaying the requested state")
    func readbackMismatch() {
        let system = FakeTimeAnnouncements()
        system.ignoreWrites = true
        let controller = TimeAnnouncementController(backend: system.backend)
        controller.setEnabled(false)
        #expect(controller.isEnabled)
        #expect(controller.errorMessage != nil)
    }

    @Test("Read failure prevents writes")
    func readFailure() {
        let system = FakeTimeAnnouncements()
        system.readFails = true
        let controller = TimeAnnouncementController(backend: system.backend)
        #expect(controller.errorMessage != nil)
        controller.setEnabled(true)
        #expect(system.writes == 0)
    }
}

@MainActor
private final class FakeTimeAnnouncements {
    enum Failure: Error { case requested }
    var preferences: [String: Any] = [
        "TimeAnnouncementsEnabled": true,
        "TimeAnnouncementsIntervalIdentifier": "EveryQuarterHourInterval",
        "TimeAnnouncementsVoiceSettings": [
            "CustomVolume": 0.36,
            "VoiceSelection": ["voiceId": "example-voice"]
        ],
        "FutureSetting": "preserved"
    ]
    var readFails = false
    var writeFails = false
    var ignoreWrites = false
    var writes = 0

    var backend: TimeAnnouncementBackend {
        TimeAnnouncementBackend(
            readPreferences: {
                if self.readFails { throw Failure.requested }
                return self.preferences
            },
            writePreferences: {
                if self.writeFails { throw Failure.requested }
                self.writes += 1
                if !self.ignoreWrites { self.preferences = $0 }
            }
        )
    }
}
