import Foundation
import Services

private func printUsage() {
    print("LaunchShieldHelperDaemon")
    print("Usage:")
    print("  helper state")
    print("  helper begin-uninstall")
    print("  helper uninstall --nonce <value> [--dry-run]")
    print("  helper grace --reason <text>")
    print("  helper recover")
}

private func value(after flag: String, in args: [String]) -> String? {
    guard let idx = args.firstIndex(of: flag), args.indices.contains(idx + 1) else { return nil }
    return args[idx + 1]
}

let args = Array(CommandLine.arguments.dropFirst())
let uninstallService = UninstallService()
let coordinator = ProtectionCoordinator()

guard let cmd = args.first else {
    printUsage()
    exit(1)
}

switch cmd {
case "state":
    let state = coordinator.refreshState()
    print("mode=\(state.mode.rawValue) helper=\(state.helperInstalled) agent=\(state.agentInstalled) app=\(state.mainAppPresent)")

case "begin-uninstall":
    do {
        let challenge = try uninstallService.beginUninstallFlow()
        print("nonce=\(challenge.nonce)")
        print("expiresAt=\(challenge.expiresAt)")
    } catch {
        fputs("error: \(error.localizedDescription)\n", stderr)
        exit(2)
    }

case "uninstall":
    guard let nonce = value(after: "--nonce", in: args) else {
        fputs("missing --nonce\n", stderr)
        exit(2)
    }
    let dryRun = args.contains("--dry-run")
    do {
        let report = try uninstallService.performFullUninstall(challengeNonce: nonce, requireRoot: true, dryRun: dryRun)
        print("removed=\(report.removedPaths.count) failures=\(report.failures.count)")
        if !report.removedPaths.isEmpty {
            print("removed paths:")
            report.removedPaths.forEach { print("  \($0)") }
        }
        if !report.failures.isEmpty {
            print("failed paths:")
            report.failures.forEach { print("  \($0)") }
            exit(3)
        }
    } catch {
        fputs("error: \(error.localizedDescription)\n", stderr)
        exit(2)
    }

case "grace":
    let reason = value(after: "--reason", in: args) ?? "manual"
    coordinator.enterGraceMode(reason: reason)
    print("grace mode entered")

case "recover":
    coordinator.recoverToNormal()
    print("recovered to normal mode")

default:
    printUsage()
    exit(1)
}
