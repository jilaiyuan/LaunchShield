#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT_YML="$ROOT_DIR/project.yml"

if ! grep -q 'macOS: "12.0"' "$PROJECT_YML"; then
  echo "ERROR: Deployment target in project.yml is not macOS 12.0"
  exit 1
fi

echo "OK: project deployment target is macOS 12.0 (compatible with Monterey 12.7.5)."
