#!/bin/sh
# Pre-commit secret scan of staged changes. Fails closed if gitleaks is missing.
if ! command -v gitleaks >/dev/null 2>&1; then
  echo "gitleaks is required for commits. Install it (Windows: winget install Gitleaks.Gitleaks) and restart your shell." >&2
  exit 1
fi
exec gitleaks git --pre-commit --staged --redact --no-banner --verbose
