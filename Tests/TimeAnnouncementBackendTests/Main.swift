import Darwin
import Foundation

@main
struct TimeAnnouncementBackendTests {
    @MainActor
    static func main() {
        typealias Reset = @convention(c) () -> Void
        typealias Count = @convention(c) () -> Int32
        let reset = unsafeBitCast(dlsym(UnsafeMutableRawPointer(bitPattern: -2), "MTBFixtureReset"), to: Reset.self)
        let count = unsafeBitCast(dlsym(UnsafeMutableRawPointer(bitPattern: -2), "MTBFixtureApplyCount"), to: Count.self)
        let failApply = unsafeBitCast(dlsym(UnsafeMutableRawPointer(bitPattern: -2), "MTBFixtureFailApply"), to: Reset.self)
        reset()
        let controller = TimeAnnouncementController()
        var failures = 0
        func check(_ condition: Bool, _ label: String) {
            print("\(condition ? "PASS" : "FAIL"): \(label)")
            if !condition { failures += 1 }
        }
        for (index, enabled) in [false, true].enumerated() {
            controller.setEnabled(enabled)
            check(count() == Int32(index + 1), "\(enabled ? "On" : "Off") uses the speech-preferences setter, not a file-only write")
            check(controller.isEnabled == enabled && controller.errorMessage == nil, "Saved state matches the requested state")
            let preferences = try! TimeAnnouncementBackend.system.readPreferences()
            check(preferences["TimeAnnouncementsIntervalIdentifier"] as? String == "EveryQuarterHourInterval", "Interval preserved")
            check((preferences["TimeAnnouncementsVoiceSettings"] as? [String: Double])?["CustomVolume"] == 0.36, "Voice settings preserved")
        }
        failApply()
        controller.setEnabled(false)
        check(controller.isEnabled && controller.errorMessage != nil, "Native setter failure is reported without claiming the setting changed")
        exit(failures == 0 ? 0 : 1)
    }
}
