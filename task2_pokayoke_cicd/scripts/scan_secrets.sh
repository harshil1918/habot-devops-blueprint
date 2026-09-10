#!/usr/bin/env bash
# =============================================================================
# Task 2 - Hardcoded secret scanner (fail-closed).
# Author: Harshil Parmar | Contact: harshilparmar1907@gmil.com | +91 9824624715
#
# Greps tracked source files for common credential patterns. Any match prints
# the offending location and exits 1, which halts the CI job. Exit 0 only when
# the tree is clean.
# =============================================================================
set -euo pipefail

echo "Running hardcoded-secret scan..."

# Patterns: generic API keys, AWS keys, GCP service-account private keys,
# and obvious assignments like  api_key = "sk_live_..."
PATTERNS=(
  'AKIA[0-9A-Z]{16}'
  'sk_live_[0-9a-zA-Z]{16,}'
  'AIza[0-9A-Za-z_-]{35}'
  '-----BEGIN( RSA)? PRIVATE KEY-----'
  '(api[_-]?key|secret|password|token)[[:space:]]*[:=][[:space:]]*["'"'"'][^"'"'"']{8,}'
)

# Scan tracked files only; skip this scanner and the .git directory.
FILES=$(git ls-files | grep -vE '(^|/)scan_secrets\.sh$' || true)

HITS=0
for pattern in "${PATTERNS[@]}"; do
  while IFS= read -r match; do
    [ -z "$match" ] && continue
    echo "::error::Potential hardcoded secret -> $match"
    HITS=$((HITS + 1))
  done < <(echo "$FILES" | xargs -r grep -InE "$pattern" 2>/dev/null || true)
done

if [ "$HITS" -gt 0 ]; then
  echo "FAIL-CLOSED: $HITS potential secret(s) detected. Build halted."
  exit 1
fi

echo "PASS: no hardcoded secrets detected."
exit 0
