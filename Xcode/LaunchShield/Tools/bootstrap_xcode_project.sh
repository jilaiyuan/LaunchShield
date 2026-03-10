#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

if ! command -v xcodegen >/dev/null 2>&1; then
  echo "xcodegen is required. Install with: brew install xcodegen" >&2
  exit 1
fi

xcodegen generate

echo "Generated: $ROOT_DIR/LaunchShield.xcodeproj"
echo "Next steps:"
echo "1) Open LaunchShield.xcodeproj in Xcode"
echo "2) Set DEVELOPMENT_TEAM for all targets"
echo "3) Build LaunchShieldHelper first, then LaunchShield"
