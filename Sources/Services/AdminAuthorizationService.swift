import Core
import AppKit
import Foundation
import Security

public final class AdminAuthorizationService {
    public init() {}

    public func authorizeAdmin(prompt: String = "Authenticate to reset LaunchShield password") throws {
        _ = prompt
        var authRef: AuthorizationRef?
        let createStatus = AuthorizationCreate(nil, nil, [], &authRef)
        guard createStatus == errAuthorizationSuccess, let authRef else {
            try authorizeAdminViaAppleScript(prompt: prompt, originalStatus: createStatus)
            return
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
            try authorizeAdminViaAppleScript(prompt: prompt, originalStatus: copyStatus)
            return
        }
    }

    private func authorizeAdminViaAppleScript(prompt: String, originalStatus: OSStatus) throws {
        let escapedPrompt = prompt
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")

        let script = """
        do shell script "echo LaunchShieldAuthOK >/dev/null" with administrator privileges with prompt "\(escapedPrompt)"
        """

        var errorDict: NSDictionary?
        guard let appleScript = NSAppleScript(source: script) else {
            throw AppError.adminAuthorizationFailedWithStatus(stage: "AppleScriptInit", status: originalStatus)
        }

        let result = appleScript.executeAndReturnError(&errorDict)
        if let errorDict {
            let code = (errorDict[NSAppleScript.errorNumber] as? Int).map(OSStatus.init) ?? originalStatus
            throw AppError.adminAuthorizationFailedWithStatus(stage: "AppleScriptExecute", status: code)
        }

        // Keep a minor use of result to avoid warnings and assert successful execution.
        _ = result.stringValue
    }
}
