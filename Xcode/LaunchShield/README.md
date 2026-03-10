# LaunchShield Xcode SMJobBless Skeleton

This folder contains a real macOS `SMJobBless` + privileged `NSXPC` wiring skeleton in Xcode-oriented structure.

## Structure

- `MainApp/`
  - `HelperBlessingService.swift`: runs `AuthorizationCreate` + `SMJobBless`.
  - `HelperXPCClient.swift`: privileged `NSXPCConnection` client.
  - `HelperBootstrapController.swift`: installs helper and connects XPC.
  - `AdminUninstallController.swift`: challenge-based uninstall call flow.
- `PrivilegedHelper/`
  - `main.swift`: launches `NSXPCListener(machServiceName:)`.
  - `HelperListenerDelegate.swift`: accepts XPC connections.
  - `HelperService.swift`: implementation calling `ProtectionCoordinator` and `UninstallService`.
- `SharedXPC/`
  - `LaunchShieldXPCProtocol.swift`: shared XPC contract.
  - `XPCConstants.swift`: helper service naming constants.
- `Configs/`
  - `MainApp-Info.plist`: includes `SMPrivilegedExecutables` mapping.
  - `Helper-Info.plist`: includes `MachServices` + `SMAuthorizedClients`.
  - Entitlements for app and helper.
- `Launchd/com.launchshield.helper.plist`
  - launchd plist template for helper.
- `project.yml`
  - XcodeGen spec for app/helper/uninstaller targets using local package products (`Core`, `Services`).

## Generate Xcode project

```bash
cd Xcode/LaunchShield
./Tools/bootstrap_xcode_project.sh
```

## Required signing setup

Before first successful bless, set `DEVELOPMENT_TEAM` in all targets, then ensure these requirements match your Team ID:

- `Configs/MainApp-Info.plist` -> `SMPrivilegedExecutables`
- `Configs/Helper-Info.plist` -> `SMAuthorizedClients`

## End-to-end flow

1. Build and run app target.
2. App calls `HelperBlessingService.blessHelper()`.
3. Helper is installed under `/Library/PrivilegedHelperTools` and launched by launchd.
4. App connects via privileged XPC and calls helper methods.
5. Admin uninstall path:
   - issue uninstall challenge
   - perform full uninstall with nonce validation (root helper execution)

## Notes

- This is a production-style skeleton, not yet full release packaging.
- Next hardening steps: install-time helper embedding, helper-side audit token policy expansion, notarized `.pkg` pipeline in CI.
