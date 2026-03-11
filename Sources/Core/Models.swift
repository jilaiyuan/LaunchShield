import Foundation

public struct PolicySnapshot: Codable, Sendable {
    public var blacklist: Set<String>
    public var systemExemptions: Set<String>
    public var protectionMode: ProtectionMode
    public var schedule: WeeklyBlockSchedule

    public init(
        blacklist: Set<String> = [],
        systemExemptions: Set<String> = PolicySnapshot.defaultSystemExemptions,
        protectionMode: ProtectionMode = .standard,
        schedule: WeeklyBlockSchedule = WeeklyBlockSchedule()
    ) {
        self.blacklist = blacklist
        self.systemExemptions = systemExemptions
        self.protectionMode = protectionMode
        self.schedule = schedule
    }

    private enum CodingKeys: String, CodingKey {
        case blacklist
        case systemExemptions
        case protectionMode
        case schedule
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        blacklist = try container.decodeIfPresent(Set<String>.self, forKey: .blacklist) ?? []
        systemExemptions = try container.decodeIfPresent(Set<String>.self, forKey: .systemExemptions) ?? PolicySnapshot.defaultSystemExemptions
        protectionMode = try container.decodeIfPresent(ProtectionMode.self, forKey: .protectionMode) ?? .standard
        schedule = try container.decodeIfPresent(WeeklyBlockSchedule.self, forKey: .schedule) ?? WeeklyBlockSchedule()
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(blacklist, forKey: .blacklist)
        try container.encode(systemExemptions, forKey: .systemExemptions)
        try container.encode(protectionMode, forKey: .protectionMode)
        try container.encode(schedule, forKey: .schedule)
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

public enum Weekday: Int, CaseIterable, Codable, Hashable, Sendable, Identifiable {
    case monday = 1
    case tuesday = 2
    case wednesday = 3
    case thursday = 4
    case friday = 5
    case saturday = 6
    case sunday = 7

    public var id: Int { rawValue }

    public var title: String {
        switch self {
        case .monday: return "Monday"
        case .tuesday: return "Tuesday"
        case .wednesday: return "Wednesday"
        case .thursday: return "Thursday"
        case .friday: return "Friday"
        case .saturday: return "Saturday"
        case .sunday: return "Sunday"
        }
    }

    public static func from(calendarWeekday: Int) -> Weekday? {
        switch calendarWeekday {
        case 1: return .sunday
        case 2: return .monday
        case 3: return .tuesday
        case 4: return .wednesday
        case 5: return .thursday
        case 6: return .friday
        case 7: return .saturday
        default: return nil
        }
    }
}

public struct BlockTimeWindow: Codable, Sendable, Equatable {
    public var startMinute: Int
    public var endMinute: Int

    public init(startMinute: Int, endMinute: Int) {
        self.startMinute = max(0, min(1_439, startMinute))
        self.endMinute = max(1, min(1_440, endMinute))
    }
}

public struct WeeklyBlockSchedule: Codable, Sendable, Equatable {
    public var windows: [Weekday: BlockTimeWindow]

    public init(windows: [Weekday: BlockTimeWindow] = [:]) {
        self.windows = windows
    }
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
