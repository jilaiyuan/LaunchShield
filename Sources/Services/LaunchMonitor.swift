import AppKit
import Core
import Foundation

public struct RunningAppContext: Sendable {
    public let bundleID: String
    public let appName: String
    public let bundleURL: URL?
    public let pid: Int32

    public init(bundleID: String, appName: String, bundleURL: URL?, pid: Int32) {
        self.bundleID = bundleID
        self.appName = appName
        self.bundleURL = bundleURL
        self.pid = pid
    }
}

@MainActor
public final class LaunchMonitor: NSObject {
    public typealias BlockedLaunchHandler = (_ context: RunningAppContext, _ completion: @escaping (Bool) -> Void) -> Void

    public var onBlockedLaunch: BlockedLaunchHandler?

    private let policyStore: PolicyStore
    private let evaluator: LaunchPolicyEvaluator
    private var isObserving = false

    public init(policyStore: PolicyStore, evaluator: LaunchPolicyEvaluator = LaunchPolicyEvaluator()) {
        self.policyStore = policyStore
        self.evaluator = evaluator
        super.init()
    }

    public func start() {
        guard !isObserving else { return }
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(handleLaunchNotification(_:)),
            name: NSWorkspace.didLaunchApplicationNotification,
            object: nil
        )
        isObserving = true
    }

    public func stop() {
        guard isObserving else { return }
        NSWorkspace.shared.notificationCenter.removeObserver(self)
        isObserving = false
    }

    public func grantOneTimePermit(bundleID: String, pid: Int32) {
        evaluator.addOneTimePermit(bundleID: bundleID, pid: pid)
    }

    @objc private func handleLaunchNotification(_ notification: Notification) {
        guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else {
            return
        }

        let policy = policyStore.load()
        let decision = evaluator.evaluate(bundleID: app.bundleIdentifier, pid: app.processIdentifier, policy: policy)

        switch decision {
        case .allow:
            return
        case .block:
            blockAndRequestPassword(for: app)
        }
    }

    private func blockAndRequestPassword(for app: NSRunningApplication) {
        guard let bundleID = app.bundleIdentifier else { return }

        _ = app.forceTerminate()

        let context = RunningAppContext(
            bundleID: bundleID,
            appName: app.localizedName ?? bundleID,
            bundleURL: app.bundleURL,
            pid: app.processIdentifier
        )

        onBlockedLaunch?(context) { [weak self] approved in
            guard
                let self,
                approved,
                let bundleURL = context.bundleURL
            else { return }

            self.evaluator.addOneTimePermit(bundleID: context.bundleID, pid: context.pid)
            NSWorkspace.shared.openApplication(at: bundleURL, configuration: NSWorkspace.OpenConfiguration()) { _, _ in }
        }
    }
}
