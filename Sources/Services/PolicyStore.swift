import Core
import Foundation

public final class PolicyStore: @unchecked Sendable {
    private let policyURL: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let queue = DispatchQueue(label: "com.launchshield.policystore")

    public init(baseDirectory: URL? = nil) {
        let root = baseDirectory ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDir = root.appendingPathComponent("LaunchShield", isDirectory: true)
        self.policyURL = appDir.appendingPathComponent("policy.json")
    }

    public func load() -> PolicySnapshot {
        queue.sync {
            do {
                let data = try Data(contentsOf: policyURL)
                return try decoder.decode(PolicySnapshot.self, from: data)
            } catch {
                return PolicySnapshot()
            }
        }
    }

    public func save(_ snapshot: PolicySnapshot) throws {
        try queue.sync {
            let dir = policyURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            let data = try encoder.encode(snapshot)
            try data.write(to: policyURL, options: [.atomic])
        }
    }

    public func setBlacklist(_ bundleIDs: Set<String>) throws {
        var policy = load()
        policy.blacklist = bundleIDs
        try save(policy)
    }
}
