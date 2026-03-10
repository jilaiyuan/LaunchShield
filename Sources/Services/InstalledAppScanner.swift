import AppKit
import Core
import Foundation

public enum InstalledAppScanner {
    public static func scan() -> [InstalledApp] {
        let searchDirs = [
            URL(fileURLWithPath: "/Applications", isDirectory: true),
            FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Applications", isDirectory: true),
            URL(fileURLWithPath: "/System/Applications", isDirectory: true)
        ]

        var seen = Set<String>()
        var results: [InstalledApp] = []

        for dir in searchDirs {
            guard let enumerator = FileManager.default.enumerator(
                at: dir,
                includingPropertiesForKeys: [.isDirectoryKey],
                options: [.skipsHiddenFiles, .skipsPackageDescendants]
            ) else {
                continue
            }

            for case let appURL as URL in enumerator {
                guard appURL.pathExtension == "app" else { continue }
                guard let bundle = Bundle(url: appURL), let bundleID = bundle.bundleIdentifier else { continue }
                guard !seen.contains(bundleID) else { continue }

                let appName = bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
                    ?? bundle.object(forInfoDictionaryKey: "CFBundleName") as? String
                    ?? appURL.deletingPathExtension().lastPathComponent

                seen.insert(bundleID)
                results.append(InstalledApp(bundleID: bundleID, name: appName, path: appURL.path))
            }
        }

        return results.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }
}
