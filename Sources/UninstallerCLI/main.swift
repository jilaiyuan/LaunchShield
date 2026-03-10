import Foundation
import Services

private func usage() {
    print("LaunchShieldUninstaller")
    print("Usage:")
    print("  uninstaller dry-run")
    print("  uninstaller full")
    print("Note: 'full' must run as root (sudo).")
}

let args = Array(CommandLine.arguments.dropFirst())
guard let command = args.first else {
    usage()
    exit(1)
}

let uninstallService = UninstallService()

switch command {
case "dry-run":
    do {
        let challenge = try uninstallService.beginUninstallFlow()
        let report = try uninstallService.performFullUninstall(challengeNonce: challenge.nonce, requireRoot: false, dryRun: true)
        print("Dry-run cleanup targets:")
        report.removedPaths.forEach { print("  \($0)") }
    } catch {
        fputs("error: \(error.localizedDescription)\n", stderr)
        exit(2)
    }

case "full":
    do {
        let challenge = try uninstallService.beginUninstallFlow()
        let report = try uninstallService.performFullUninstall(challengeNonce: challenge.nonce, requireRoot: true, dryRun: false)
        print("Uninstall finished. Removed \(report.removedPaths.count) items.")
        if !report.failures.isEmpty {
            print("Failures:")
            report.failures.forEach { print("  \($0)") }
            exit(3)
        }
    } catch {
        fputs("error: \(error.localizedDescription)\n", stderr)
        exit(2)
    }

default:
    usage()
    exit(1)
}
