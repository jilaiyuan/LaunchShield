import Core
import Foundation
import Services

final class HelperService: NSObject, LaunchShieldXPCProtocol {
    private let coordinator = ProtectionCoordinator()
    private let uninstallService = UninstallService()

    func ping(reply: @escaping (String) -> Void) {
        reply("pong from helper")
    }

    func queryProtectionState(reply: @escaping (Data?, String?) -> Void) {
        let state = coordinator.refreshState()
        do {
            let data = try JSONEncoder().encode(state)
            reply(data, nil)
        } catch {
            reply(nil, error.localizedDescription)
        }
    }

    func issueUninstallChallenge(reply: @escaping (String?, Date?, String?) -> Void) {
        do {
            let challenge = try uninstallService.beginUninstallFlow()
            reply(challenge.nonce, challenge.expiresAt, nil)
        } catch {
            reply(nil, nil, error.localizedDescription)
        }
    }

    func performFullUninstall(challengeNonce: String, dryRun: Bool, reply: @escaping (Bool, [String], [String], String?) -> Void) {
        do {
            let report = try uninstallService.performFullUninstall(
                challengeNonce: challengeNonce,
                requireRoot: true,
                dryRun: dryRun
            )
            reply(report.failures.isEmpty, report.removedPaths, report.failures, nil)
        } catch {
            reply(false, [], [], error.localizedDescription)
        }
    }

    func enterGraceMode(reason: String, hours: Int, reply: @escaping (Bool, String?) -> Void) {
        coordinator.enterGraceMode(reason: reason, durationHours: max(hours, 1))
        reply(true, nil)
    }

    func recoverToNormal(reply: @escaping (Bool, String?) -> Void) {
        coordinator.recoverToNormal()
        reply(true, nil)
    }
}
