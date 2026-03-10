import Foundation
import Security
import ServiceManagement

enum HelperBlessError: LocalizedError {
    case authorization(OSStatus)
    case blessFailed(String)

    var errorDescription: String? {
        switch self {
        case .authorization(let status):
            return "Authorization failed: \(status)"
        case .blessFailed(let message):
            return "SMJobBless failed: \(message)"
        }
    }
}

final class HelperBlessingService {
    func blessHelper() throws {
        var authRef: AuthorizationRef?
        let status = AuthorizationCreate(nil, nil, [.interactionAllowed, .extendRights, .preAuthorize], &authRef)
        guard status == errAuthorizationSuccess, let authRef else {
            throw HelperBlessError.authorization(status)
        }
        defer { AuthorizationFree(authRef, [.destroyRights]) }

        var cfError: Unmanaged<CFError>?
        let ok = SMJobBless(
            kSMDomainSystemLaunchd,
            XPCConstants.helperLabel as CFString,
            authRef,
            &cfError
        )

        if !ok {
            let msg = (cfError?.takeRetainedValue() as Error?)?.localizedDescription ?? "unknown"
            throw HelperBlessError.blessFailed(msg)
        }
    }
}
