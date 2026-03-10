# LaunchShield
LaunchShield is an open-source macOS app lock and launch-control tool. It lets you maintain a blacklist of apps and requires a password before blacklisted apps can open.

## One-click Manual Release on GitHub
This repository includes a manual GitHub Actions workflow that builds a signed and notarized `.pkg`, then publishes it to GitHub Releases.

Workflow file:
- `.github/workflows/release-manual.yml`

### 1) Configure repository secrets (once)
Go to `GitHub -> Settings -> Secrets and variables -> Actions` and add:

- `DEVELOPMENT_TEAM`: Apple Team ID
- `APPLICATION_SIGNING_IDENTITY`: e.g. `Developer ID Application: Your Name (TEAMID)`
- `INSTALLER_SIGNING_IDENTITY`: e.g. `Developer ID Installer: Your Name (TEAMID)`
- `KEYCHAIN_PASSWORD`: temporary CI keychain password
- `APP_CERT_P12_BASE64`: base64 of Developer ID Application `.p12`
- `APP_CERT_P12_PASSWORD`: password of that `.p12`
- `INSTALLER_CERT_P12_BASE64`: base64 of Developer ID Installer `.p12`
- `INSTALLER_CERT_P12_PASSWORD`: password of that `.p12`
- `APPLE_ID`: your Apple ID email
- `APPLE_APP_SPECIFIC_PASSWORD`: app-specific password for notarytool

### 2) Run release job manually
Go to `Actions -> Manual Release (pkg) -> Run workflow`:

- `version`: e.g. `1.0.0`
- `make_latest`: `true` or `false`

The job will:
1. Generate Xcode project with XcodeGen
2. Import signing certs
3. Build + sign + notarize `.pkg`
4. Create tag `v<version>`
5. Create GitHub Release and upload `LaunchShield-<version>.pkg`

### 3) Users download from Releases
After success, users can install directly from your GitHub Release page asset.
