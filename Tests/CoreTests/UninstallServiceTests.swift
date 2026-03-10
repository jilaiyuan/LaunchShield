import Foundation
import Services
import XCTest

final class UninstallServiceTests: XCTestCase {
    func testDryRunIncludesTargets() throws {
        let home = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: home, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: home) }

        let layout = InstallLayout(
            appBundlePath: home.appendingPathComponent("Applications/LaunchShield.app").path,
            helperPath: home.appendingPathComponent("Library/PrivilegedHelperTools/com.launchshield.helper").path,
            helperLaunchdPlist: home.appendingPathComponent("Library/LaunchDaemons/com.launchshield.helper.plist").path,
            userLaunchAgentPlist: home.appendingPathComponent("Library/LaunchAgents/com.launchshield.agent.plist").path,
            userSupportPath: home.appendingPathComponent("Library/Application Support/LaunchShield").path,
            userLogPath: home.appendingPathComponent("Library/Logs/LaunchShield").path
        )

        let challengeService = UninstallChallengeService(baseDirectory: home)
        let stateStore = ProtectionStateStore(baseDirectory: home)
        let service = UninstallService(layout: layout, challengeService: challengeService, stateStore: stateStore)

        let challenge = try service.beginUninstallFlow()
        let report = try service.performFullUninstall(challengeNonce: challenge.nonce, requireRoot: false, dryRun: true)

        XCTAssertTrue(report.failures.isEmpty)
        XCTAssertGreaterThanOrEqual(report.removedPaths.count, 6)
    }
}
