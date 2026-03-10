# Contributing to LaunchShield

## Development setup

1. Install Xcode and Swift toolchain.
2. Clone repository.
3. Run:

```bash
swift test
```

4. For SMJobBless/XPC work, use:

```bash
cd Xcode/LaunchShield
./Tools/bootstrap_xcode_project.sh
```

## Contribution rules

- Keep changes focused and reviewable.
- Add or update tests for behavior changes.
- Keep macOS target compatible with Monterey 12.7.5+.
- Prefer secure defaults for any helper/XPC/auth code changes.

## Pull request checklist

- [ ] Tests pass (`swift test`)
- [ ] README/docs updated for behavior changes
- [ ] No secrets/cert material committed
- [ ] Breaking changes called out in PR description
