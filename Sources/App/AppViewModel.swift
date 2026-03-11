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
    @Published var uninstallDebugLogPath: String = ""

    private let policyStore: PolicyStore
    private let passwordService: PasswordService
    private let adminAuthorizationService: AdminAuthorizationService
    private let launchMonitor: LaunchMonitor
    private let uninstallService: UninstallService
    private let autoLaunchService: AutoLaunchService
    private var passwordMessageHideWorkItem: DispatchWorkItem?

    init(
        policyStore: PolicyStore = PolicyStore(),
        passwordService: PasswordService = PasswordService(),
        adminAuthorizationService: AdminAuthorizationService = AdminAuthorizationService(),
        uninstallService: UninstallService = UninstallService(),
        autoLaunchService: AutoLaunchService = AutoLaunchService()
    ) {
        self.policyStore = policyStore
        self.passwordService = passwordService
        self.adminAuthorizationService = adminAuthorizationService
        self.uninstallService = uninstallService
        self.autoLaunchService = autoLaunchService
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

        if let executablePath = Bundle.main.executablePath {
            autoLaunchService.ensureEnabled(executablePath: executablePath)
        }

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
            showPasswordMessage("Passwords do not match.")
            return
        }

        do {
            try passwordService.createPassword(password)
            hasPassword = true
            showPasswordMessage("Unlock password has been created successfully.")
            password = ""
            confirmPassword = ""
        } catch {
            showPasswordMessage(error.localizedDescription)
        }
    }

    func resetPasswordUsingAdminMode() {
        guard password == confirmPassword else {
            showPasswordMessage("Passwords do not match.")
            return
        }

        do {
            NSApp.activate(ignoringOtherApps: true)
            try adminAuthorizationService.authorizeAdmin()
            try passwordService.resetPassword(password)
            showPasswordMessage("Unlock password has been reset successfully.")
            password = ""
            confirmPassword = ""
            hasPassword = true
        } catch {
            showPasswordMessage(error.localizedDescription)
        }
    }

    func prepareAdminUninstallCommand() {
        var debugLines: [String] = []
        let ts = ISO8601DateFormatter().string(from: Date())
        debugLines.append("time=\(ts)")
        debugLines.append("cwd=\(FileManager.default.currentDirectoryPath)")
        debugLines.append("bundlePath=\(Bundle.main.bundlePath)")
        debugLines.append("executablePath=\(Bundle.main.executablePath ?? "nil")")

        if FileManager.default.fileExists(atPath: "/Library/PrivilegedHelperTools/com.launchshield.helper") {
            debugLines.append("step=installed_helper_detected")
            uninstallCommand = "sudo /Library/PrivilegedHelperTools/com.launchshield.helper uninstall-direct"
            uninstallHint = "Run in Terminal. You will be prompted for admin password by sudo."
            debugLines.append("mode=installed_helper_direct")
            debugLines.append("helperPath=/Library/PrivilegedHelperTools/com.launchshield.helper")
        } else if let bundledHelper = detectBundledHelperBinary() {
            debugLines.append("step=bundled_helper_detected")
            uninstallCommand = "sudo \"\(bundledHelper)\" uninstall-direct"
            uninstallHint = "Run in Terminal. sudo will request admin password."
            debugLines.append("mode=bundled_helper_direct")
            debugLines.append("helperPath=\(bundledHelper)")
        } else if let projectRoot = detectProjectRoot() {
            uninstallCommand = "sudo swift run --package-path \"\(projectRoot)\" LaunchShieldUninstaller full"
            uninstallHint = "Development environment command. Run in Terminal; sudo will request admin password."
            debugLines.append("mode=package_path_uninstaller_full")
            debugLines.append("projectRoot=\(projectRoot)")
        } else {
            uninstallCommand = ""
            uninstallHint = "Could not auto-detect project root. Run from your repository root: sudo swift run LaunchShieldUninstaller full"
            debugLines.append("mode=detect_failed")
        }
        debugLines.append("finalCommand=\(uninstallCommand)")
        uninstallDebugLogPath = writeUninstallDebugLog(lines: debugLines) ?? ""
        statusMessage = "Admin uninstall command has been generated."
    }

    private func persistBlacklist() {
        isBusy = true
        Task {
            do {
                try policyStore.setBlacklist(blacklist)
                await MainActor.run {
                    self.blacklistStatusMessage = "Blacklist saved automatically. Checked = added, unchecked = removed."
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
            if !ok {
                showPasswordMessage("Incorrect unlock password.")
            }
        } catch {
            showPasswordMessage("Failed to verify unlock password.")
            completion(false)
        }
    }

    private func showPasswordMessage(_ message: String) {
        passwordMessageHideWorkItem?.cancel()
        // Force refresh even if the same message is emitted consecutively.
        passwordStatusMessage = ""
        DispatchQueue.main.async {
            self.passwordStatusMessage = message
        }

        let workItem = DispatchWorkItem { [weak self] in
            self?.passwordStatusMessage = ""
        }
        passwordMessageHideWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 5, execute: workItem)
    }

    private func detectProjectRoot() -> String? {
        if let cwdRoot = findPackageRoot(startingAt: FileManager.default.currentDirectoryPath) {
            return cwdRoot
        }

        if let executablePath = Bundle.main.executablePath {
            let executableDir = URL(fileURLWithPath: executablePath).deletingLastPathComponent().path
            if let executableRoot = findPackageRoot(startingAt: executableDir) {
                return executableRoot
            }
        }

        let bundlePath = Bundle.main.bundleURL.path
        if let bundleRoot = findPackageRoot(startingAt: bundlePath) {
            return bundleRoot
        }

        let sourceFilePath = #filePath
        let suffix = "/Sources/App/AppViewModel.swift"
        if sourceFilePath.hasSuffix(suffix) {
            let candidate = String(sourceFilePath.dropLast(suffix.count))
            if let sourceRoot = findPackageRoot(startingAt: candidate) {
                return sourceRoot
            }
        }

        return nil
    }

    private func findPackageRoot(startingAt path: String) -> String? {
        var currentURL = URL(fileURLWithPath: path, isDirectory: true)
        let fm = FileManager.default

        for _ in 0..<16 {
            let packagePath = currentURL.appendingPathComponent("Package.swift").path
            if fm.fileExists(atPath: packagePath) {
                return currentURL.path
            }

            let parent = currentURL.deletingLastPathComponent()
            if parent.path == currentURL.path || parent.path.isEmpty {
                break
            }
            currentURL = parent
        }

        return nil
    }

    private func detectBundledHelperBinary() -> String? {
        guard let executablePath = Bundle.main.executablePath else { return nil }
        let executableDir = URL(fileURLWithPath: executablePath).deletingLastPathComponent()
        let candidates = [
            executableDir.appendingPathComponent("LaunchShieldHelperDaemon").path,
            executableDir.deletingLastPathComponent().appendingPathComponent("MacOS/LaunchShieldHelperDaemon").path
        ]

        for candidate in candidates where FileManager.default.isExecutableFile(atPath: candidate) {
            return candidate
        }
        return nil
    }

    private func writeUninstallDebugLog(lines: [String]) -> String? {
        let fileName = "uninstall_debug_\(Int(Date().timeIntervalSince1970)).log"
        let fm = FileManager.default
        var candidateDirs: [URL] = []

        if let appSupport = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            candidateDirs.append(
                appSupport
                    .appendingPathComponent("LaunchShield", isDirectory: true)
                    .appendingPathComponent("logs", isDirectory: true)
            )
        }

        candidateDirs.append(fm.homeDirectoryForCurrentUser.appendingPathComponent("Desktop/LaunchShieldLogs", isDirectory: true))
        candidateDirs.append(URL(fileURLWithPath: "/tmp/LaunchShieldLogs", isDirectory: true))

        let body = lines.joined(separator: "\n") + "\n"
        for base in candidateDirs {
            do {
                try fm.createDirectory(at: base, withIntermediateDirectories: true)
                let url = base.appendingPathComponent(fileName)
                try body.write(to: url, atomically: true, encoding: .utf8)
                return url.path
            } catch {
                continue
            }
        }
        return nil
    }
}
