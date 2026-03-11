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
    @Published var passwordStatusMessage: String = ""
    @Published var blacklistStatusMessage: String = ""
    @Published var uninstallCommand: String = ""
    @Published var uninstallHint: String = ""

    private let policyStore: PolicyStore
    private let passwordService: PasswordService
    private let adminAuthorizationService: AdminAuthorizationService
    private let launchMonitor: LaunchMonitor
    private let uninstallService: UninstallService

    init(
        policyStore: PolicyStore = PolicyStore(),
        passwordService: PasswordService = PasswordService(),
        adminAuthorizationService: AdminAuthorizationService = AdminAuthorizationService(),
        uninstallService: UninstallService = UninstallService()
    ) {
        self.policyStore = policyStore
        self.passwordService = passwordService
        self.adminAuthorizationService = adminAuthorizationService
        self.uninstallService = uninstallService
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
            passwordStatusMessage = "两次输入的密码不一致。"
            return
        }

        do {
            try passwordService.createPassword(password)
            hasPassword = true
            passwordStatusMessage = "已成功设置解锁密码（用于打开黑名单 App）。"
            password = ""
            confirmPassword = ""
        } catch {
            passwordStatusMessage = error.localizedDescription
        }
    }

    func resetPasswordUsingAdminMode() {
        guard password == confirmPassword else {
            passwordStatusMessage = "两次输入的密码不一致。"
            return
        }

        do {
            try adminAuthorizationService.authorizeAdmin()
            try passwordService.resetPassword(password)
            passwordStatusMessage = "已成功重置解锁密码。"
            password = ""
            confirmPassword = ""
            hasPassword = true
        } catch {
            passwordStatusMessage = error.localizedDescription
        }
    }

    func prepareAdminUninstallCommand() {
        do {
            try adminAuthorizationService.authorizeAdmin(prompt: "Authenticate to prepare full uninstall")
            let challenge = try uninstallService.beginUninstallFlow()
            if FileManager.default.fileExists(atPath: "/Library/PrivilegedHelperTools/com.launchshield.helper") {
                uninstallCommand = "sudo /Library/PrivilegedHelperTools/com.launchshield.helper uninstall --nonce \(challenge.nonce)"
                uninstallHint = "生产安装环境：直接执行上面的命令。"
            } else {
                uninstallCommand = "cd \"<项目根目录>\" && sudo swift run LaunchShieldHelperDaemon uninstall --nonce \(challenge.nonce)"
                uninstallHint = "开发环境：请在项目根目录执行。出现 command not found 通常是因为 helper 不在 PATH。"
            }
            statusMessage = "已生成管理员卸载命令。"
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
                    self.blacklistStatusMessage = "黑名单已自动保存。勾选=加入，取消=移除。"
                    self.isBusy = false
                }
            } catch {
                await MainActor.run {
                    self.blacklistStatusMessage = error.localizedDescription
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
