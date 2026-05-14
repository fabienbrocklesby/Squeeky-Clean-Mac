import AppKit
import CoreGraphics
import Foundation

enum InputLockState: Equatable {
    case idle
    case locked(progress: Double)
    case unlocked
}

enum InputLockError: Error {
    case eventTapUnavailable
}

final class InputLockService: @unchecked Sendable {
    static let unlockHoldDuration: TimeInterval = 3

    var onStateChange: ((InputLockState) -> Void)?

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var holdTimer: Timer?
    private var holdStartedAt: Date?
    private var isLeftCommandDown = false
    private var isRightCommandDown = false
    private var isLocked = false
    private var cursorWasDecoupled = false

    private static let leftCommandFlag = CGEventFlags(rawValue: 0x00000008)
    private static let rightCommandFlag = CGEventFlags(rawValue: 0x00000010)

    deinit {
        stop()
    }

    func lock() throws {
        stop()
        resetUnlockGesture()

        let callback: CGEventTapCallBack = { proxy, type, event, userInfo in
            guard let userInfo else {
                return Unmanaged.passUnretained(event)
            }

            let service = Unmanaged<InputLockService>.fromOpaque(userInfo).takeUnretainedValue()
            return service.handleEvent(proxy: proxy, type: type, event: event)
        }

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: Self.eventMask,
            callback: callback,
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            throw InputLockError.eventTapUnavailable
        }

        guard let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0) else {
            CFMachPortInvalidate(tap)
            throw InputLockError.eventTapUnavailable
        }

        eventTap = tap
        runLoopSource = source
        isLocked = true

        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        lockCursorMovement()
        onStateChange?(.locked(progress: 0))
    }

    func stop() {
        holdTimer?.invalidate()
        holdTimer = nil

        if let eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
            CFMachPortInvalidate(eventTap)
        }

        if let runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        }

        eventTap = nil
        runLoopSource = nil
        isLocked = false
        resetUnlockGesture()
        unlockCursorMovement()
    }

    private func unlock() {
        stop()
        onStateChange?(.unlocked)
    }

    private func handleEvent(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        guard isLocked else {
            return Unmanaged.passUnretained(event)
        }

        switch type {
        case .tapDisabledByTimeout, .tapDisabledByUserInput:
            if let eventTap {
                CGEvent.tapEnable(tap: eventTap, enable: true)
            }
            return Unmanaged.passUnretained(event)
        case .flagsChanged:
            updateCommandState(from: event)
            updateUnlockGesture()
        default:
            break
        }

        return nil
    }

    private func updateCommandState(from event: CGEvent) {
        let flags = event.flags
        isLeftCommandDown = flags.contains(Self.leftCommandFlag)
        isRightCommandDown = flags.contains(Self.rightCommandFlag)
    }

    private func updateUnlockGesture() {
        guard isLeftCommandDown && isRightCommandDown else {
            resetUnlockGesture()
            onStateChange?(.locked(progress: 0))
            return
        }

        if holdStartedAt == nil {
            holdStartedAt = Date()
            startHoldTimer()
        }
    }

    private func startHoldTimer() {
        holdTimer?.invalidate()

        let timer = Timer(timeInterval: 1 / 30, repeats: true) { [weak self] _ in
            self?.tickHoldTimer()
        }

        holdTimer = timer
        RunLoop.main.add(timer, forMode: .common)
        timer.fire()
    }

    private func tickHoldTimer() {
        guard let holdStartedAt else {
            return
        }

        let elapsed = Date().timeIntervalSince(holdStartedAt)
        let progress = min(1, elapsed / Self.unlockHoldDuration)
        onStateChange?(.locked(progress: progress))

        if progress >= 1 {
            unlock()
        }
    }

    private func resetUnlockGesture() {
        holdStartedAt = nil
        holdTimer?.invalidate()
        holdTimer = nil
    }

    private func lockCursorMovement() {
        guard !cursorWasDecoupled else {
            return
        }

        if CGAssociateMouseAndMouseCursorPosition(boolean_t(0)) == .success {
            cursorWasDecoupled = true
        }
    }

    private func unlockCursorMovement() {
        guard cursorWasDecoupled else {
            return
        }

        CGAssociateMouseAndMouseCursorPosition(boolean_t(1))
        cursorWasDecoupled = false
    }

    private static let filteredEventTypes: [CGEventType] = [
        .keyDown,
        .keyUp,
        .flagsChanged,
        .leftMouseDown,
        .leftMouseUp,
        .rightMouseDown,
        .rightMouseUp,
        .otherMouseDown,
        .otherMouseUp,
        .mouseMoved,
        .leftMouseDragged,
        .rightMouseDragged,
        .otherMouseDragged,
        .scrollWheel
    ]

    private static var eventMask: CGEventMask {
        filteredEventTypes.reduce(CGEventMask(0)) { mask, type in
            mask | (CGEventMask(1) << CGEventMask(type.rawValue))
        }
    }
}
