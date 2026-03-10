import Core
import Foundation

public final class ProtectionCoordinator: @unchecked Sendable {
    private let layout: InstallLayout
    private let stateStore: ProtectionStateStore

    public init(layout: InstallLayout = .default(), stateStore: ProtectionStateStore = ProtectionStateStore()) {
        self.layout = layout
        self.stateStore = stateStore
    }

    public func refreshState() -> ProtectionState {
        var state = stateStore.load()
        state.mainAppPresent = FileManager.default.fileExists(atPath: layout.appBundlePath)
        state.helperInstalled = FileManager.default.fileExists(atPath: layout.helperPath)
        state.agentInstalled = FileManager.default.fileExists(atPath: layout.userLaunchAgentPlist)

        if !state.mainAppPresent && state.mode == .normal {
            state.mode = .grace
            state.graceReason = "Main app bundle missing"
            state.graceUntil = Date().addingTimeInterval(24 * 3600)
        }

        try? stateStore.save(state)
        return state
    }

    public func enterGraceMode(reason: String, durationHours: Int = 24) {
        try? stateStore.enterGraceMode(reason: reason, durationHours: durationHours)
    }

    public func recoverToNormal() {
        try? stateStore.setModeNormal()
    }
}
