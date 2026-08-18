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

archive=$repo_root/dist/$package.tar.gz
outer_manifest=$archive.sha256
first_archive=$proof_root/first-$package.tar.gz
first_manifest=$first_archive.sha256

"$repo_root/scripts/build-bundle.sh" > "$proof_root/first-build.out"
cp "$archive" "$first_archive"
cp "$outer_manifest" "$first_manifest"
sleep 2
"$repo_root/scripts/build-bundle.sh" > "$proof_root/second-build.out"
cmp "$first_archive" "$archive" >/dev/null || fail 'two builds produced different archives'
cmp "$first_manifest" "$outer_manifest" >/dev/null || fail 'two builds produced different outer checksum files'
source_epoch=$(git -C "$repo_root" show -s --format=%ct HEAD)
python3 "$repo_root/tests/verify-bundle-metadata.py" "$archive" "$package" "$source_epoch"
archive_hash=$(awk 'NR == 1 { print $1 }' "$outer_manifest")
printf 'Two-build reproducibility proof passed: %s\n' "$archive_hash"

"$repo_root/scripts/verify-checksums.sh" "$outer_manifest" "$repo_root/dist" > "$proof_root/outer-check.out"
tar -xzf "$archive" -C "$proof_root"
package_root=$proof_root/$package
[[ -f "$package_root/BUNDLE-SHA256SUMS" ]] || fail 'bundle manifest is missing'
if find "$package_root" -name .git -print | grep -q .; then
  fail 'bundle contains Git metadata'
fi
[[ ! -e "$package_root/vendor/nvim-plugins/luasnip/deps" ]] || fail 'bundle contains optional LuaSnip build submodules'
[[ ! -e "$package_root/vendor/nvim-plugins/luasnip/.gitmodules" ]] || fail 'bundle contains optional LuaSnip submodule metadata'
"$package_root/scripts/verify-checksums.sh" "$package_root/BUNDLE-SHA256SUMS" "$package_root" > "$proof_root/inner-check.out"
"$package_root/tests/prove-runtime.sh" "$package_root"
printf 'Offline bundle extraction and runtime proof passed.\n'
