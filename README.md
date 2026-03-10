# LaunchShield

LaunchShield is an open-source macOS app lock and launch-control tool. It uses a blacklist model and requires a password before blacklisted GUI apps can open.

Target OS: macOS Monterey 12.7.5+

## Release Workflows on GitHub

This repo provides two manual release jobs:

1. **Signed + Notarized Release** (recommended for end users)
- Workflow: `.github/workflows/release-manual.yml`
- Requires Apple Developer paid-program certificates and notarization credentials.
- Output: `LaunchShield-<version>.pkg` on GitHub Release.

2. **Community Unsigned Release** (no paid certs required)
- Workflow: `.github/workflows/release-community.yml`
- Does not require Developer ID certs or notarization.
- Output:
  - `LaunchShield-<version>-community.pkg`
  - `LaunchShield-<version>-community.zip`

## How to Trigger Community Release

Go to: `GitHub -> Actions -> Manual Community Release (unsigned) -> Run workflow`

Inputs:
- `version`: e.g. `1.0.0`
- `make_latest`: `true` or `false`

The job will:
1. Generate Xcode project using XcodeGen.
2. Build unsigned `LaunchShield.app`.
3. Package unsigned `.pkg` and `.zip`.
4. Create tag `v<version>-community`.
5. Create GitHub Release and upload artifacts.

## How Users Install Unsigned Community Build

Because community artifacts are unsigned/unnotarized, macOS Gatekeeper will block them by default.

### Option A: GUI allow (recommended for normal users)
1. Download community `.pkg` or `.zip` from Releases.
2. If using `.pkg`: right-click installer -> `Open` -> confirm `Open`.
3. If app is still blocked after install:
- Open `System Settings -> Privacy & Security`.
- In the security section, click `Open Anyway` for LaunchShield.
- Then right-click `LaunchShield.app` and click `Open` once.

### Option B: Terminal allow (for technical users)
If app is in `/Applications`:

```bash
sudo xattr -dr com.apple.quarantine "/Applications/LaunchShield.app"
```

Then run once:

```bash
open "/Applications/LaunchShield.app"
```

## Important Notes

- Unsigned community builds are for testing/internal use.
- For broad public distribution, use signed+notarized workflow.
- Helper hardening and SMJobBless flow are in `Xcode/LaunchShield`.

## Signed Release Setup (Paid Developer Program)

Workflow: `.github/workflows/release-manual.yml`

Required GitHub Secrets:
- `DEVELOPMENT_TEAM`
- `APPLICATION_SIGNING_IDENTITY`
- `INSTALLER_SIGNING_IDENTITY`
- `KEYCHAIN_PASSWORD`
- `APP_CERT_P12_BASE64`
- `APP_CERT_P12_PASSWORD`
- `INSTALLER_CERT_P12_BASE64`
- `INSTALLER_CERT_P12_PASSWORD`
- `APPLE_ID`
- `APPLE_APP_SPECIFIC_PASSWORD`
