import Core
import Darwin
import Foundation

public struct UninstallReport: Sendable {
    public let removedPaths: [String]
    public let failures: [String]

    public init(removedPaths: [String], failures: [String]) {
        self.removedPaths = removedPaths
        self.failures = failures
    }
}

public final class UninstallService: @unchecked Sendable {
    private let layout: InstallLayout
    private let challengeService: UninstallChallengeService
    private let stateStore: ProtectionStateStore

    public init(
        layout: InstallLayout = .default(),
        challengeService: UninstallChallengeService = UninstallChallengeService(),
        stateStore: ProtectionStateStore = ProtectionStateStore()
    ) {
        self.layout = layout
        self.challengeService = challengeService
        self.stateStore = stateStore
    }

    public func beginUninstallFlow() throws -> UninstallChallenge {
        try challengeService.issue()
    }

    public func performFullUninstall(challengeNonce: String, requireRoot: Bool = true, dryRun: Bool = false) throws -> UninstallReport {
        try challengeService.validateAndConsume(nonce: challengeNonce)
        return try executeCleanup(requireRoot: requireRoot, dryRun: dryRun, clearChallengeOnSuccess: true)
    }

    public func performFullUninstallDirect(requireRoot: Bool = true, dryRun: Bool = false) throws -> UninstallReport {
        try executeCleanup(requireRoot: requireRoot, dryRun: dryRun, clearChallengeOnSuccess: false)
    }

    private func executeCleanup(requireRoot: Bool, dryRun: Bool, clearChallengeOnSuccess: Bool) throws -> UninstallReport {
        if requireRoot && geteuid() != 0 {
            throw AppError.uninstallRequiresRoot
        }

        let targets = [
            layout.userLaunchAgentPlist,
            layout.helperLaunchdPlist,
            layout.helperPath,
            layout.userSupportPath,
            layout.userLogPath,
            layout.appBundlePath
        ]

        var removed: [String] = []
        var failures: [String] = []

        for path in targets {
            if dryRun {
                removed.append(path)
                continue
            }

            let url = URL(fileURLWithPath: path)
            if !FileManager.default.fileExists(atPath: path) {
                continue
            }
            do {
                try FileManager.default.removeItem(at: url)
                removed.append(path)
            } catch {
                failures.append(path)
            }
        }

        if dryRun {
            removed.append("keychain:com.launchshield.password")
        } else {
            // Best-effort keychain cleanup of stored password entry.
            do {
                try KeychainStore().deletePasswordRecord()
                removed.append("keychain:com.launchshield.password")
            } catch {
                removed.append("keychain:com.launchshield.password (skipped: requires user keychain context)")
            }
        }

        if failures.isEmpty {
            try? stateStore.setModeNormal()
            if clearChallengeOnSuccess {
                challengeService.clear()
            }
        }

        return UninstallReport(removedPaths: removed, failures: failures)
    }
}
