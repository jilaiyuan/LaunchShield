import Foundation

@objc protocol LaunchShieldXPCProtocol {
    func ping(reply: @escaping (String) -> Void)
    func queryProtectionState(reply: @escaping (Data?, String?) -> Void)
    func issueUninstallChallenge(reply: @escaping (String?, Date?, String?) -> Void)
    func performFullUninstall(challengeNonce: String, dryRun: Bool, reply: @escaping (Bool, [String], [String], String?) -> Void)
    func enterGraceMode(reason: String, hours: Int, reply: @escaping (Bool, String?) -> Void)
    func recoverToNormal(reply: @escaping (Bool, String?) -> Void)
}
