import Core
import Foundation
import Security

public final class AdminAuthorizationService {
    public init() {}

    public func authorizeAdmin(prompt: String = "Authenticate to reset LaunchShield password") throws {
        _ = prompt
        var authRef: AuthorizationRef?
        let createFlags: AuthorizationFlags = [.interactionAllowed, .extendRights, .preAuthorize]
        let createStatus = AuthorizationCreate(nil, nil, createFlags, &authRef)
        guard createStatus == errAuthorizationSuccess, let authRef else {
            throw AppError.adminAuthorizationFailedWithStatus(stage: "AuthorizationCreate", status: createStatus)
        }

        defer {
            AuthorizationFree(authRef, [.destroyRights])
        }

        let flags: AuthorizationFlags = [
            .interactionAllowed,
            .extendRights,
            .preAuthorize
        ]

        let copyStatus = kAuthorizationRightExecute.withCString { rightName in
            var right = AuthorizationItem(name: rightName, valueLength: 0, value: nil, flags: 0)
            return withUnsafeMutablePointer(to: &right) { rightPointer in
                var rights = AuthorizationRights(count: 1, items: rightPointer)
                return AuthorizationCopyRights(authRef, &rights, nil, flags, nil)
            }
        }

        guard copyStatus == errAuthorizationSuccess else {
            throw AppError.adminAuthorizationFailedWithStatus(stage: "AuthorizationCopyRights", status: copyStatus)
        }
    }
}
