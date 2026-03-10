import Foundation

public struct PolicySnapshot: Codable, Sendable {
    public var blacklist: Set<String>
    public var systemExemptions: Set<String>
    public var protectionMode: ProtectionMode

    public init(
        blacklist: Set<String> = [],
        systemExemptions: Set<String> = PolicySnapshot.defaultSystemExemptions,
        protectionMode: ProtectionMode = .standard
    ) {
        self.blacklist = blacklist
        self.systemExemptions = systemExemptions
        self.protectionMode = protectionMode
    }

    public static let defaultSystemExemptions: Set<String> = [
        "com.apple.finder",
        "com.apple.dock",
        "com.apple.systempreferences",
        "com.apple.ActivityMonitor"
    ]
}

public enum ProtectionMode: String, Codable, Sendable {
    case standard
}

public struct PasswordRecord: Codable, Sendable {
    public let saltBase64: String
    public let iterations: Int
    public let hashBase64: String

    public init(saltBase64: String, iterations: Int, hashBase64: String) {
        self.saltBase64 = saltBase64
        self.iterations = iterations
        self.hashBase64 = hashBase64
    }
}

public struct OneTimePermit: Sendable {
    public let bundleID: String
    public var pid: Int32
    public let issuedAt: Date
    public var consumed: Bool

    public init(bundleID: String, pid: Int32, issuedAt: Date = Date(), consumed: Bool = false) {
        self.bundleID = bundleID
        self.pid = pid
        self.issuedAt = issuedAt
        self.consumed = consumed
    }
}

public enum LaunchDecision: Sendable {
    case allow
    case block(reason: BlockReason)
}

public enum BlockReason: Sendable {
    case blacklisted
    case missingBundleID
}

public struct InstalledApp: Identifiable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let path: String

    public init(bundleID: String, name: String, path: String) {
        self.id = bundleID
        self.name = name
        self.path = path
    }
}
