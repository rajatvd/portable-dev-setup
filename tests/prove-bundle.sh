#!/usr/bin/env bash
set -euo pipefail

repo_root=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
version=$(cat "$repo_root/VERSION")
package=portable-dev-setup-$version
proof_root=$(mktemp -d "${TMPDIR:-/tmp}/portable-dev-setup-bundle-proof.XXXXXX")
trap 'rm -rf "$proof_root"' EXIT

fail() {
  printf 'BUNDLE PROOF FAILED: %s\n' "$*" >&2
  exit 1
}

"$repo_root/scripts/build-bundle.sh" > "$proof_root/build.out"
archive=$repo_root/dist/$package.tar.gz
outer_manifest=$archive.sha256
"$repo_root/scripts/verify-checksums.sh" "$outer_manifest" "$repo_root/dist" > "$proof_root/outer-check.out"
tar -xzf "$archive" -C "$proof_root"
package_root=$proof_root/$package
[[ -f "$package_root/BUNDLE-SHA256SUMS" ]] || fail 'bundle manifest is missing'
if find "$package_root" -name .git -print | grep -q .; then
  fail 'bundle contains Git metadata'
fi
"$package_root/scripts/verify-checksums.sh" "$package_root/BUNDLE-SHA256SUMS" "$package_root" > "$proof_root/inner-check.out"
"$package_root/tests/prove-runtime.sh" "$package_root"
printf 'Offline bundle extraction and runtime proof passed.\n'
