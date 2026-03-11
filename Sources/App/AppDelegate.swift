import AppKit
import Services

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let adminAuthorizationService = AdminAuthorizationService()
    private var authorizedQuit = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Background-style app: keep monitoring active without Dock presence.
        NSApp.setActivationPolicy(.accessory)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        if authorizedQuit {
            return .terminateNow
        }

        do {
            try adminAuthorizationService.authorizeAdmin(prompt: "Authenticate to quit LaunchShield")
            authorizedQuit = true
            return .terminateNow
        } catch {
            return .terminateCancel
        }
    }
}
