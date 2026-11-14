import AppKit
import Combine
import Foundation

// Keep the nested voice, interval, and any future macOS settings intact.
struct TimeAnnouncementPreferences {
    static func isEnabled(in preferences: [String: Any]) -> Bool {
        (preferences["TimeAnnouncementsEnabled"] as? NSNumber)?.boolValue ?? false
    }

    static func settingEnabled(_ enabled: Bool, in preferences: [String: Any]) -> [String: Any] {
        var updated = preferences
        updated["TimeAnnouncementsEnabled"] = enabled
        return updated
    }
}

@MainActor
struct TimeAnnouncementBackend {
    let readPreferences: () throws -> [String: Any]
    let writePreferences: ([String: Any]) throws -> Void
    let notifySystem: (Bool) async throws -> Void

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
            CFPreferencesSetAppValue(key, preferences as CFDictionary, domain)
            guard CFPreferencesAppSynchronize(domain) else {
                throw TimeAnnouncementError.preferencesUnavailable
            }
        },
        notifySystem: { enabled in
            if enabled {
                // macOS renamed SpeechSynthesisServer.app to System Speech.app.
                // Open the system's existing service without activating its UI.
                let directory = "/System/Library/Frameworks/ApplicationServices.framework/Versions/A/Frameworks/SpeechSynthesis.framework/Versions/A"
                guard let url = ["System Speech.app", "SpeechSynthesisServer.app"]
                    .map({ URL(fileURLWithPath: directory).appendingPathComponent($0) })
                    .first(where: { FileManager.default.fileExists(atPath: $0.path) }) else {
                    throw TimeAnnouncementError.speechServiceUnavailable
                }
                let configuration = NSWorkspace.OpenConfiguration()
                configuration.activates = false
                configuration.addsToRecentItems = false
                _ = try await NSWorkspace.shared.openApplication(at: url, configuration: configuration)
            }
            // The system speech service observes this notification to resync its timer.
            DistributedNotificationCenter.default().postNotificationName(
                Notification.Name("AppleTimePreferencesChangedNotification"),
                object: nil,
                userInfo: nil,
                deliverImmediately: true
            )
        }
    )
}

private enum TimeAnnouncementError: Error {
    case preferencesUnavailable
    case speechServiceUnavailable
    case readbackMismatch
}

@MainActor
final class TimeAnnouncementController: ObservableObject {
    @Published private(set) var isEnabled = false
    @Published private(set) var isChanging = false
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

    func setEnabled(_ enabled: Bool) async {
        guard !isChanging else { return }
        isChanging = true
        defer { isChanging = false }
        do {
            let preferences = try backend.readPreferences()
            try backend.writePreferences(TimeAnnouncementPreferences.settingEnabled(enabled, in: preferences))
            try await backend.notifySystem(enabled)
            isEnabled = TimeAnnouncementPreferences.isEnabled(in: try backend.readPreferences())
            guard isEnabled == enabled else { throw TimeAnnouncementError.readbackMismatch }
            errorMessage = nil
        } catch {
            refresh()
            errorMessage = "Could not apply time announcements. Try Clock Options in System Settings."
        }
    }
}
