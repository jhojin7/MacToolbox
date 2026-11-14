import Combine
import Foundation
import SystemControlsShim

// Keep the nested voice, interval, and any future macOS settings intact.
struct TimeAnnouncementPreferences {
    static func isEnabled(in preferences: [String: Any]) -> Bool {
        (preferences["TimeAnnouncementsEnabled"] as? NSNumber)?.boolValue ?? false
    }

    static func settingEnabled(_ enabled: Bool, in preferences: [String: Any]) -> [String: Any] {
        var updated = preferences
        // The system setter reads this value using CFNumberGetValue.
        updated["TimeAnnouncementsEnabled"] = enabled ? 1 : 0
        return updated
    }
}

@MainActor
struct TimeAnnouncementBackend {
    let readPreferences: () throws -> [String: Any]
    let writePreferences: ([String: Any]) throws -> Void

    private static let domain = "com.apple.speech.synthesis.general.prefs" as CFString
    private static let key = "TimeAnnouncementPrefs" as CFString

    static let system = TimeAnnouncementBackend(
        readPreferences: {
            guard CFPreferencesAppSynchronize(domain) else {
                throw TimeAnnouncementError.preferencesUnavailable
            }
            guard let value = CFPreferencesCopyAppValue(key, domain) else { return [:] }
            guard let preferences = value as? [String: Any] else {
                throw TimeAnnouncementError.preferencesUnavailable
            }
            return preferences
        },
        writePreferences: { preferences in
            guard MTBSetTimeAnnouncementPreferences(preferences as CFDictionary) else {
                throw TimeAnnouncementError.preferencesUnavailable
            }
        }
    )
}

private enum TimeAnnouncementError: Error {
    case preferencesUnavailable
    case readbackMismatch
}

@MainActor
final class TimeAnnouncementController: ObservableObject {
    @Published private(set) var isEnabled = false
    @Published private(set) var errorMessage: String?

    private let backend: TimeAnnouncementBackend

    init(backend: TimeAnnouncementBackend = .system) {
        self.backend = backend
        refresh()
    }

    func refresh() {
        do {
            isEnabled = TimeAnnouncementPreferences.isEnabled(in: try backend.readPreferences())
        } catch {
            errorMessage = "Could not read time announcements. Check Clock Options in System Settings."
        }
    }

    func setEnabled(_ enabled: Bool) {
        do {
            let preferences = try backend.readPreferences()
            try backend.writePreferences(TimeAnnouncementPreferences.settingEnabled(enabled, in: preferences))
            isEnabled = TimeAnnouncementPreferences.isEnabled(in: try backend.readPreferences())
            guard isEnabled == enabled else { throw TimeAnnouncementError.readbackMismatch }
            errorMessage = nil
        } catch {
            refresh()
            errorMessage = "Could not apply time announcements. Try Clock Options in System Settings."
        }
    }
}
