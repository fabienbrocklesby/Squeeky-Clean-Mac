import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    @MainActor
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
    }

    @MainActor
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    @MainActor
    func configureWindow() {
        guard let window = NSApp.windows.first(where: { $0.identifier?.rawValue == "SqueekyCleanMac.MainWindow" }) ?? NSApp.keyWindow else {
            return
        }

        window.identifier = NSUserInterfaceItemIdentifier("SqueekyCleanMac.MainWindow")
        window.title = "Squeeky Clean Mac"
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = true
        window.standardWindowButton(.zoomButton)?.isHidden = true
        window.collectionBehavior = [.fullScreenNone]
        window.level = .floating
        window.center()
    }
}
