import Foundation

public enum AppError: LocalizedError {
    case invalidPasswordPolicy
    case failedToGenerateSalt
    case invalidStoredPasswordRecord
    case keychainOSStatus(OSStatus)
    case adminAuthorizationFailed
    case adminAuthorizationFailedWithStatus(stage: String, status: OSStatus)
    case uninstallChallengeExpired
    case uninstallChallengeInvalid
    case uninstallRequiresRoot
    case fileOperationFailed(path: String)

    public var errorDescription: String? {
        switch self {
        case .invalidPasswordPolicy:
            return "Password must be 8-64 characters with letters and numbers."
        case .failedToGenerateSalt:
            return "Failed to generate a secure salt."
        case .invalidStoredPasswordRecord:
            return "Stored password record is invalid."
        case .keychainOSStatus(let status):
            return "Keychain operation failed with status: \(status)."
        case .adminAuthorizationFailed:
            return "Administrator authorization failed."
        case .adminAuthorizationFailedWithStatus(let stage, let status):
            return "Administrator authorization failed at \(stage) with OSStatus \(status)."
        case .uninstallChallengeExpired:
            return "Uninstall challenge expired."
        case .uninstallChallengeInvalid:
            return "Uninstall challenge is invalid."
        case .uninstallRequiresRoot:
            return "Full uninstall requires root privileges."
        case .fileOperationFailed(let path):
            return "Failed to remove file at path: \(path)."
        }
    }
}
