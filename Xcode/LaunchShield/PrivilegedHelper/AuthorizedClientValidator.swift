import Foundation
import Security

final class AuthorizedClientValidator {
    private let allowedRequirements: [String]

    init() {
        let reqs = Bundle.main.object(forInfoDictionaryKey: "SMAuthorizedClients") as? [String]
        self.allowedRequirements = reqs ?? []
    }

    func isAuthorized(connection: NSXPCConnection) -> Bool {
        guard let code = copyGuestCode(for: connection) else {
            return false
        }

        for requirementString in allowedRequirements {
            if matches(code: code, requirement: requirementString) {
                return true
            }
        }
        return false
    }

    private func copyGuestCode(for connection: NSXPCConnection) -> SecCode? {
        var auditToken = connection.auditToken
        let tokenData = Data(bytes: &auditToken, count: MemoryLayout.size(ofValue: auditToken)) as CFData

        let attributes = [
            kSecGuestAttributeAudit as String: tokenData
        ] as CFDictionary

        var codeRef: SecCode?
        let status = SecCodeCopyGuestWithAttributes(nil, attributes, SecCSFlags(), &codeRef)
        guard status == errSecSuccess else {
            return nil
        }
        return codeRef
    }

    private func matches(code: SecCode, requirement: String) -> Bool {
        var requirementRef: SecRequirement?
        let createStatus = SecRequirementCreateWithString(requirement as CFString, SecCSFlags(), &requirementRef)
        guard createStatus == errSecSuccess, let requirementRef else {
            return false
        }

        let checkStatus = SecCodeCheckValidity(code, SecCSFlags(), requirementRef)
        return checkStatus == errSecSuccess
    }
}
