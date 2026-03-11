// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "LaunchShield",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .executable(name: "LaunchShield", targets: ["App"]),
        .executable(name: "LaunchShieldHelperDaemon", targets: ["HelperDaemon"]),
        .executable(name: "LaunchShieldUninstaller", targets: ["UninstallerCLI"]),
        .library(name: "Core", targets: ["Core"]),
        .library(name: "Services", targets: ["Services"])
    ],
    targets: [
        .target(
            name: "Core"
        ),
        .target(
            name: "Services",
            dependencies: ["Core"]
        ),
        .executableTarget(
            name: "App",
            dependencies: ["Core", "Services"],
            path: "Sources/App"
        ),
        .executableTarget(
            name: "HelperDaemon",
            dependencies: ["Core", "Services"],
            path: "Sources/HelperDaemon"
        ),
        .executableTarget(
            name: "UninstallerCLI",
            dependencies: ["Core", "Services"],
            path: "Sources/UninstallerCLI"
        ),
        .testTarget(
            name: "CoreTests",
            dependencies: ["Core", "Services"],
            path: "Tests/CoreTests"
        )
    ]
)
