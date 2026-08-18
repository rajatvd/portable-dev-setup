#!/usr/bin/env bash
set -euo pipefail

manifest=${1:?usage: verify-checksums.sh MANIFEST ROOT}
root=${2:?usage: verify-checksums.sh MANIFEST ROOT}

fail() {
  printf 'checksum error: %s\n' "$*" >&2
  exit 1
}

sha256_file() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | awk '{print $1}'
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$1" | awk '{print $1}'
  else
    fail 'sha256sum or shasum is required'
  fi
}

[[ -f "$manifest" ]] || fail "missing manifest: $manifest"
[[ -d "$root" ]] || fail "missing root: $root"

count=0
while IFS= read -r line || [[ -n "$line" ]]; do
  [[ -n "$line" ]] || continue
  expected=${line%%  *}
  relative=${line#*  }
  [[ "$relative" != "$line" ]] || fail 'malformed manifest line'
  [[ "$expected" =~ ^[0-9a-f]{64}$ ]] || fail "invalid SHA-256 for $relative"
  case "$relative" in
    ./*) ;;
    *) fail "unsafe manifest path: $relative" ;;
  esac
  case "/$relative/" in
    */../*) fail "unsafe manifest path: $relative" ;;
  esac
  file=$root/${relative#./}
  [[ -f "$file" ]] || fail "missing file: $relative"
  actual=$(sha256_file "$file")
  [[ "$actual" == "$expected" ]] || fail "mismatch: $relative"
  count=$((count + 1))
done < "$manifest"

[[ "$count" -gt 0 ]] || fail 'manifest is empty'
printf 'Verified %d SHA-256 checksums.\n' "$count"
