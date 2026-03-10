import Foundation

public enum RuntimeMode: String, Codable, Sendable {
    case normal
    case grace
}

public struct ProtectionState: Codable, Sendable {
    public var helperInstalled: Bool
    public var agentInstalled: Bool
    public var mainAppPresent: Bool
    public var mode: RuntimeMode
    public var graceReason: String?
    public var graceUntil: Date?
    public var lastError: String?

    public init(
        helperInstalled: Bool = false,
        agentInstalled: Bool = false,
        mainAppPresent: Bool = true,
        mode: RuntimeMode = .normal,
        graceReason: String? = nil,
        graceUntil: Date? = nil,
        lastError: String? = nil
    ) {
        self.helperInstalled = helperInstalled
        self.agentInstalled = agentInstalled
        self.mainAppPresent = mainAppPresent
        self.mode = mode
        self.graceReason = graceReason
        self.graceUntil = graceUntil
        self.lastError = lastError
    }
}

public enum RequiredAuth: String, Codable, Sendable {
    case systemAdmin
}

public struct UninstallChallenge: Codable, Sendable {
    public let nonce: String
    public let issuedAt: Date
    public let expiresAt: Date
    public let requiredAuth: RequiredAuth

    public init(nonce: String, issuedAt: Date, expiresAt: Date, requiredAuth: RequiredAuth = .systemAdmin) {
        self.nonce = nonce
        self.issuedAt = issuedAt
        self.expiresAt = expiresAt
        self.requiredAuth = requiredAuth
    }

    public var isExpired: Bool {
        Date() > expiresAt
    }
}

public struct OperationResult: Codable, Sendable {
    public let success: Bool
    public let message: String
    public let code: Int

    public init(success: Bool, message: String, code: Int = 0) {
        self.success = success
        self.message = message
        self.code = code
    }
}
