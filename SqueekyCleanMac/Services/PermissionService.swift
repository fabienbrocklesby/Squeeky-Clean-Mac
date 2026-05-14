import AppKit
import ApplicationServices
import CoreGraphics

struct PermissionService {
    private let accessibilityPromptOptionKey = "AXTrustedCheckOptionPrompt"

    func currentState() -> PermissionState {
        let hasInputMonitoring = CGPreflightListenEventAccess()
        let hasAccessibility = AXIsProcessTrusted()

        switch (hasInputMonitoring, hasAccessibility) {
        case (true, true):
            return .ready
        case (false, false):
            return .needsAccessibilityAndInputMonitoring
        case (false, true):
            return .readyWithInputMonitoringWarning
        case (true, false):
            return .needsAccessibility
        }
    }

    func requestMissingPermissions() -> PermissionState {
        if !CGPreflightListenEventAccess() {
            _ = CGRequestListenEventAccess()
        }

        if !AXIsProcessTrusted() {
            let options = [
                accessibilityPromptOptionKey: true
            ] as CFDictionary

            _ = AXIsProcessTrustedWithOptions(options)
        }

        return currentState()
    }

    func openRelevantSettings(for state: PermissionState) {
        let urlString: String

        switch state {
        case .needsAccessibility, .needsAccessibilityAndInputMonitoring, .unknown:
            urlString = "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
        case .readyWithInputMonitoringWarning:
            urlString = "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent"
        case .ready:
            return
        }

        guard let url = URL(string: urlString) else {
            return
        }

        NSWorkspace.shared.open(url)
    }
}
