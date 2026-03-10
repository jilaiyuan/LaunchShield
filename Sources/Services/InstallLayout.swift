import Foundation

public struct InstallLayout: Sendable {
    public let appBundlePath: String
    public let helperPath: String
    public let helperLaunchdPlist: String
    public let userLaunchAgentPlist: String
    public let userSupportPath: String
    public let userLogPath: String

    public init(
        appBundlePath: String,
        helperPath: String,
        helperLaunchdPlist: String,
        userLaunchAgentPlist: String,
        userSupportPath: String,
        userLogPath: String
    ) {
        self.appBundlePath = appBundlePath
        self.helperPath = helperPath
        self.helperLaunchdPlist = helperLaunchdPlist
        self.userLaunchAgentPlist = userLaunchAgentPlist
        self.userSupportPath = userSupportPath
        self.userLogPath = userLogPath
    }

    public static func `default`() -> InstallLayout {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        return InstallLayout(
            appBundlePath: "/Applications/LaunchShield.app",
            helperPath: "/Library/PrivilegedHelperTools/com.launchshield.helper",
            helperLaunchdPlist: "/Library/LaunchDaemons/com.launchshield.helper.plist",
            userLaunchAgentPlist: "\(home)/Library/LaunchAgents/com.launchshield.agent.plist",
            userSupportPath: "\(home)/Library/Application Support/LaunchShield",
            userLogPath: "\(home)/Library/Logs/LaunchShield"
        )
    }
}
