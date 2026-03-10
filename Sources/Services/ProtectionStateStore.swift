import Core
import Foundation

public final class ProtectionStateStore: @unchecked Sendable {
    private let stateURL: URL
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()
    private let queue = DispatchQueue(label: "com.launchshield.protectionstate")

    public init(baseDirectory: URL? = nil) {
        let root = baseDirectory ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDir = root.appendingPathComponent("LaunchShield", isDirectory: true)
        self.stateURL = appDir.appendingPathComponent("protection_state.json")
    }

    public func load() -> ProtectionState {
        queue.sync {
            do {
                let data = try Data(contentsOf: stateURL)
                return try decoder.decode(ProtectionState.self, from: data)
            } catch {
                return ProtectionState()
            }
        }
    }

    public func save(_ state: ProtectionState) throws {
        try queue.sync {
            let dir = stateURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            let data = try encoder.encode(state)
            try data.write(to: stateURL, options: [.atomic])
        }
    }

    public func enterGraceMode(reason: String, durationHours: Int = 24) throws {
        var state = load()
        state.mode = .grace
        state.graceReason = reason
        state.graceUntil = Date().addingTimeInterval(TimeInterval(durationHours * 3600))
        try save(state)
    }

    public func setModeNormal() throws {
        var state = load()
        state.mode = .normal
        state.graceReason = nil
        state.graceUntil = nil
        state.lastError = nil
        try save(state)
    }
}
