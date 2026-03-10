import AppKit
import Core
import Foundation
import Services
import SwiftUI

@MainActor
final class AppViewModel: ObservableObject {
    @Published var installedApps: [InstalledApp] = []
    @Published var blacklist: Set<String> = []
    @Published var password: String = ""
    @Published var confirmPassword: String = ""
    @Published var statusMessage: String = ""
    @Published var hasPassword: Bool = false
    @Published var isBusy: Bool = false
    @Published var protectionStateSummary: String = "Unknown"
    @Published var uninstallCommand: String = ""

    private let policyStore: PolicyStore
    private let passwordService: PasswordService
    private let adminAuthorizationService: AdminAuthorizationService
    private let launchMonitor: LaunchMonitor
    private let uninstallService: UninstallService
    private let protectionCoordinator: ProtectionCoordinator

    init(
        policyStore: PolicyStore = PolicyStore(),
        passwordService: PasswordService = PasswordService(),
        adminAuthorizationService: AdminAuthorizationService = AdminAuthorizationService(),
        uninstallService: UninstallService = UninstallService(),
        protectionCoordinator: ProtectionCoordinator = ProtectionCoordinator()
    ) {
        self.policyStore = policyStore
        self.passwordService = passwordService
        self.adminAuthorizationService = adminAuthorizationService
        self.uninstallService = uninstallService
        self.protectionCoordinator = protectionCoordinator
        self.launchMonitor = LaunchMonitor(policyStore: policyStore)

        launchMonitor.onBlockedLaunch = { [weak self] context, completion in
            self?.promptForRuntimePassword(context: context, completion: completion)
        }
    }

    func bootstrap() {
        launchMonitor.start()
        hasPassword = passwordService.hasPassword()
        let policy = policyStore.load()
        blacklist = policy.blacklist

        refreshApplications()
        refreshProtectionState()
    }

    func refreshApplications() {
        installedApps = InstalledAppScanner.scan()
    }

    func isBlacklisted(_ app: InstalledApp) -> Bool {
        blacklist.contains(app.id)
    }

    func setBlacklisted(_ enabled: Bool, for app: InstalledApp) {
        if enabled {
            blacklist.insert(app.id)
        } else {
            blacklist.remove(app.id)
        }
        persistBlacklist()
    }

    func createPassword() {
        guard password == confirmPassword else {
            statusMessage = "Passwords do not match."
            return
        }

        do {
            try passwordService.createPassword(password)
            hasPassword = true
            statusMessage = "Password created."
            password = ""
            confirmPassword = ""
        } catch {
            statusMessage = error.localizedDescription
        }
    }

    func resetPasswordUsingAdminMode() {
        guard password == confirmPassword else {
            statusMessage = "Passwords do not match."
            return
        }

        do {
            try adminAuthorizationService.authorizeAdmin()
            try passwordService.resetPassword(password)
            statusMessage = "Password reset successfully."
            password = ""
            confirmPassword = ""
            hasPassword = true
        } catch {
            statusMessage = error.localizedDescription
        }
    }

    func refreshProtectionState() {
        let state = protectionCoordinator.refreshState()
        let grace = state.mode == .grace ? "grace" : "normal"
        protectionStateSummary = "mode=\(grace), helper=\(state.helperInstalled), agent=\(state.agentInstalled), app=\(state.mainAppPresent)"
    }

    func prepareAdminUninstallCommand() {
        do {
            try adminAuthorizationService.authorizeAdmin(prompt: "Authenticate to prepare full uninstall")
            let challenge = try uninstallService.beginUninstallFlow()
            uninstallCommand = "sudo LaunchShieldHelperDaemon uninstall --nonce \(challenge.nonce)"
            statusMessage = "Run the generated command in Terminal to complete full uninstall."
        } catch {
            statusMessage = error.localizedDescription
        }
    }

    private func persistBlacklist() {
        isBusy = true
        Task {
            do {
                try policyStore.setBlacklist(blacklist)
                await MainActor.run {
                    self.statusMessage = "Blacklist updated."
                    self.isBusy = false
                }
            } catch {
                await MainActor.run {
                    self.statusMessage = error.localizedDescription
                    self.isBusy = false
                }
            }
        }
    }

    private func promptForRuntimePassword(context: RunningAppContext, completion: @escaping (Bool) -> Void) {
        guard hasPassword else {
            completion(false)
            return
        }

        let alert = NSAlert()
        alert.messageText = "\(context.appName) is blacklisted"
        alert.informativeText = "Enter your control password to open this app once."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Unlock Once")
        alert.addButton(withTitle: "Cancel")

        let inputField = NSSecureTextField(frame: NSRect(x: 0, y: 0, width: 280, height: 24))
        alert.accessoryView = inputField

        let response = alert.runModal()
        guard response == .alertFirstButtonReturn else {
            completion(false)
            return
        }

        do {
            let ok = try passwordService.verify(inputField.stringValue)
            completion(ok)
        } catch {
            completion(false)
        }
    }
}
