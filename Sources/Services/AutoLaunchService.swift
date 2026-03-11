import Foundation
import Darwin

public final class AutoLaunchService: @unchecked Sendable {
    private let label = "com.launchshield.agent"

    public init() {}

    public func ensureEnabled(executablePath: String) {
        guard !executablePath.isEmpty else { return }

        let plistURL = launchAgentPlistURL()
        let payload = launchAgentPayload(executablePath: executablePath)

        do {
            let data = try PropertyListSerialization.data(fromPropertyList: payload, format: .xml, options: 0)
            try FileManager.default.createDirectory(at: plistURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            try data.write(to: plistURL, options: [.atomic])
            loadOrReloadLaunchAgent(plistURL: plistURL)
        } catch {
            NSLog("LaunchShield AutoLaunchService failed: \(error.localizedDescription)")
        }
    }

    private func launchAgentPlistURL() -> URL {
        let home = FileManager.default.homeDirectoryForCurrentUser
        return home
            .appendingPathComponent("Library", isDirectory: true)
            .appendingPathComponent("LaunchAgents", isDirectory: true)
            .appendingPathComponent("\(label).plist")
    }

    private func launchAgentPayload(executablePath: String) -> [String: Any] {
        [
            "Label": label,
            "ProgramArguments": [executablePath],
            "RunAtLoad": true,
            "KeepAlive": true,
            "ProcessType": "Interactive"
        ]
    }

    private func loadOrReloadLaunchAgent(plistURL: URL) {
        let uid = getuid()
        let domain = "gui/\(uid)"
        let plistPath = plistURL.path

        _ = runLaunchctl(["bootout", domain, plistPath])
        _ = runLaunchctl(["bootstrap", domain, plistPath])
        _ = runLaunchctl(["enable", "\(domain)/\(label)"])
        _ = runLaunchctl(["kickstart", "-k", "\(domain)/\(label)"])
    }

    @discardableResult
    private func runLaunchctl(_ arguments: [String]) -> Int32 {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/launchctl")
        process.arguments = arguments

        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus
        } catch {
            NSLog("LaunchShield launchctl failed: \(error.localizedDescription)")
            return -1
        }
    }
}
