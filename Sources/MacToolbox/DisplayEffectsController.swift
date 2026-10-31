import Combine
import Foundation
import SystemControlsShim

@MainActor
struct DisplayEffectsBackend {
    let colorFilterIsAvailable: () -> Bool
    let colorFilterIsEnabled: () -> Bool
    let setColorFilterEnabled: (Bool) -> Bool
    let nightShiftIsAvailable: () -> Bool
    let nightShiftIsEnabled: () -> Bool
    let setNightShiftEnabled: (Bool) -> Bool
    let startNightShiftStatusNotifications: () -> Bool

    static let system = DisplayEffectsBackend(
        colorFilterIsAvailable: { MTBColorFilterIsAvailable() },
        colorFilterIsEnabled: { MTBColorFilterIsEnabled() },
        setColorFilterEnabled: { MTBSetColorFilterEnabled($0) },
        nightShiftIsAvailable: { MTBNightShiftIsAvailable() },
        nightShiftIsEnabled: { MTBNightShiftIsEnabled() },
        setNightShiftEnabled: { MTBSetNightShiftEnabled($0) },
        startNightShiftStatusNotifications: { MTBStartNightShiftStatusNotifications() }
    )
}

@MainActor
final class DisplayEffectsController: ObservableObject {
    private static let nightShiftStatusDidChange = Notification.Name(
        "MTBNightShiftStatusDidChange"
    )

    @Published private(set) var colorFilterEnabled = false
    @Published private(set) var nightShiftEnabled = false
    @Published private(set) var colorFilterAvailable = false
    @Published private(set) var nightShiftAvailable = false
    @Published private(set) var errorMessage: String?

    private let backend: DisplayEffectsBackend
    private var nightShiftStatusObserver: AnyCancellable?

    init(backend: DisplayEffectsBackend = .system) {
        self.backend = backend
        refresh()
        nightShiftStatusObserver = NotificationCenter.default.publisher(
            for: Self.nightShiftStatusDidChange
        )
        .receive(on: RunLoop.main)
        .sink { [weak self] _ in
            self?.refreshNightShiftStatus()
        }
        _ = backend.startNightShiftStatusNotifications()
    }

    func refresh() {
        colorFilterAvailable = backend.colorFilterIsAvailable()
        colorFilterEnabled = colorFilterAvailable && backend.colorFilterIsEnabled()
        refreshNightShiftStatus()
    }

    private func refreshNightShiftStatus() {
        nightShiftAvailable = backend.nightShiftIsAvailable()
        nightShiftEnabled = nightShiftAvailable && backend.nightShiftIsEnabled()
    }

    func setColorFilterEnabled(_ enabled: Bool) {
        guard backend.setColorFilterEnabled(enabled) else {
            errorMessage = "Color Filters are unavailable on this macOS version"
            refresh()
            return
        }
        colorFilterEnabled = enabled
        errorMessage = nil
    }

    func setNightShiftEnabled(_ enabled: Bool) {
        guard backend.setNightShiftEnabled(enabled) else {
            errorMessage = "Night Shift could not be changed"
            refresh()
            return
        }
        refreshNightShiftStatus()
        errorMessage = nil
    }
}
