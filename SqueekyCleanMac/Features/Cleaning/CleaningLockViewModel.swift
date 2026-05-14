import AppKit
import Combine
import CoreGraphics
import Foundation
import SwiftUI

@MainActor
final class CleaningLockViewModel: ObservableObject {
    @Published private(set) var isLocked = false
    @Published private(set) var unlockProgress = 0.0
    @Published private(set) var permissionState: PermissionState = .unknown
    @Published private(set) var alert: AppAlert?

    private let inputLockService: InputLockService
    private let permissionService: PermissionService
    private var permissionRefreshTask: Task<Void, Never>?

    init(
        inputLockService: InputLockService = InputLockService(),
        permissionService: PermissionService = PermissionService()
    ) {
        self.inputLockService = inputLockService
        self.permissionService = permissionService
        refreshPermissionState()

        self.inputLockService.onStateChange = { [weak self] state in
            Task { @MainActor in
                self?.apply(lockState: state)
            }
        }
    }

    deinit {
        permissionRefreshTask?.cancel()
    }

    var menuBarSystemImage: String {
        isLocked ? "keyboard.badge.ellipsis.fill" : "sparkles"
    }

    var primaryActionTitle: String {
        if permissionState.canLock {
            return isLocked ? "Cleaning Mode Active" : "Start Cleaning Mode"
        }

        return "Enable Permissions"
    }

    var statusTitle: String {
        if isLocked {
            return unlockProgress > 0 ? "Keep holding both Command keys" : "Inputs are locked"
        }

        switch permissionState {
        case .unknown:
            return "Checking permissions"
        case .ready:
            return "Ready to clean"
        case .readyWithInputMonitoringWarning:
            return "Ready to clean"
        case .needsAccessibility:
            return "Accessibility required"
        case .needsAccessibilityAndInputMonitoring:
            return "Permissions required"
        }
    }

    var statusMessage: String {
        if isLocked {
            return "Keyboard, mouse, trackpad, clicks, gestures, and scrolling are filtered. Hold left and right Command together for 3 seconds to unlock."
        }

        switch permissionState {
        case .unknown:
            return "Squeeky Clean Mac is checking whether macOS will allow it to protect your keyboard and trackpad."
        case .ready:
            return "Start a quick cleaning session, wipe everything down, then unlock with both Command keys."
        case .readyWithInputMonitoringWarning:
            return "Cleaning mode can start. Input Monitoring has not reported as enabled yet, so grant it too if macOS asks."
        case .needsAccessibility:
            return "macOS needs Accessibility permission before this app can filter input globally."
        case .needsAccessibilityAndInputMonitoring:
            return "macOS needs Accessibility permission before cleaning mode can start. Input Monitoring may also be requested."
        }
    }

    var permissionRows: [PermissionRowState] {
        [
            PermissionRowState(title: "Accessibility", isGranted: permissionState.hasAccessibilityAccess),
            PermissionRowState(title: "Input Monitoring", isGranted: permissionState.hasInputMonitoringAccess)
        ]
    }

    var progressLabel: String {
        let seconds = max(0, Int(ceil(InputLockService.unlockHoldDuration * (1 - unlockProgress))))
        return seconds == 0 ? "Unlocking" : "\(seconds)s"
    }

    func refreshPermissionState() {
        permissionState = permissionService.currentState()
    }

    func primaryAction() {
        refreshPermissionState()

        guard permissionState.canLock else {
            requestPermissions()
            return
        }

        guard !isLocked else {
            return
        }

        do {
            try inputLockService.lock()
        } catch {
            refreshPermissionState()
            alert = AppAlert(
                title: "Could not start cleaning mode",
                message: "macOS did not allow the global input lock to start. Check Accessibility permissions, then quit and reopen the app before trying again."
            )
        }
    }

    func openSystemSettings() {
        permissionService.openRelevantSettings(for: permissionState)
    }

    func requestPermissions() {
        permissionState = permissionService.requestMissingPermissions()
        schedulePermissionRefreshes()

        if !permissionState.canLock {
            openSystemSettings()
        }
    }

    func dismissAlert() {
        alert = nil
    }

    private func apply(lockState: InputLockState) {
        switch lockState {
        case .idle:
            isLocked = false
            unlockProgress = 0
        case .locked(let progress):
            isLocked = true
            unlockProgress = progress
        case .unlocked:
            isLocked = false
            unlockProgress = 1

            withAnimation(.smooth(duration: 0.45)) {
                unlockProgress = 0
            }
        }
    }

    private func schedulePermissionRefreshes() {
        permissionRefreshTask?.cancel()
        permissionRefreshTask = Task { [weak self] in
            for delay in [300_000_000, 1_000_000_000, 2_000_000_000] {
                try? await Task.sleep(nanoseconds: UInt64(delay))

                guard !Task.isCancelled else {
                    return
                }

                self?.refreshPermissionState()
            }
        }
    }
}

enum PermissionState: Equatable {
    case unknown
    case ready
    case readyWithInputMonitoringWarning
    case needsAccessibility
    case needsAccessibilityAndInputMonitoring

    var canLock: Bool {
        hasAccessibilityAccess
    }

    var hasAccessibilityAccess: Bool {
        self == .ready || self == .readyWithInputMonitoringWarning
    }

    var hasInputMonitoringAccess: Bool {
        self == .ready || self == .needsAccessibility
    }

    var needsAttention: Bool {
        self != .ready
    }
}

struct PermissionRowState: Identifiable, Equatable {
    let title: String
    let isGranted: Bool

    var id: String { title }
}

struct AppAlert: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let message: String
}
