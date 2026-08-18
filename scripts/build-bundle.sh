#!/usr/bin/env bash
set -euo pipefail
umask 022

repo_root=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
version=$(cat "$repo_root/VERSION")
package=portable-dev-setup-$version
dist=$repo_root/dist
stage=

fail() {
  printf 'bundle error: %s\n' "$*" >&2
  exit 1
}

cleanup() {
  [[ -z "$stage" || ! -d "$stage" ]] || rm -rf "$stage"
}
trap cleanup EXIT

sha256_file() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | awk '{print $1}'
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$1" | awk '{print $1}'
  else
    fail 'sha256sum or shasum is required'
  fi
}

command -v git >/dev/null 2>&1 || fail 'git is required'
command -v python3 >/dev/null 2>&1 || fail 'python3 is required to build the bundle'
command -v tar >/dev/null 2>&1 || fail 'tar is required'
git -C "$repo_root" diff --quiet || fail 'tracked files have unstaged changes'
git -C "$repo_root" diff --cached --quiet || fail 'the index has uncommitted changes'
[[ -z "$(git -C "$repo_root" ls-files --others --exclude-standard)" ]] || fail 'untracked files are present'

source_commit=$(git -C "$repo_root" rev-parse --verify HEAD)
source_epoch=$(git -C "$repo_root" show -s --format=%ct "$source_commit")
[[ "$source_epoch" =~ ^[0-9]+$ ]] || fail "invalid source commit epoch: $source_epoch"

stage=$(mktemp -d "${TMPDIR:-/tmp}/portable-dev-setup-bundle.XXXXXX")
package_root=$stage/$package
mkdir -p "$package_root" "$dist"
git -C "$repo_root" archive --format=tar "$source_commit" | tar -xf - -C "$package_root"

while IFS=$'\t' read -r path commit kind url license; do
  [[ -n "$path" && ${path:0:1} != '#' ]] || continue
  source_dir=$repo_root/$path
  actual=$(git -C "$source_dir" rev-parse HEAD 2>/dev/null) || fail "uninitialized submodule: $path"
  [[ "$actual" == "$commit" ]] || fail "$path is at $actual; expected $commit"
  [[ -z "$(git -C "$source_dir" status --porcelain --untracked-files=all)" ]] || fail "dirty submodule: $path"
  destination=$package_root/$path
  rm -rf "$destination"
  mkdir -p "$destination"
  git -C "$source_dir" archive --format=tar "$commit" | tar -xf - -C "$destination"
  if [[ ! -f "$destination/$license" ]]; then
    mkdir -p "$(dirname -- "$destination/$license")"
    git -C "$source_dir" show "$commit:$license" > "$destination/$license"
  fi
  if [[ "$path" == vendor/nvim-plugins/luasnip ]]; then
    rm -rf "$destination/deps"
    rm -f "$destination/.gitmodules"
  fi
  printf '%s\n' "$commit" > "$destination/.portable-revision"
done < "$repo_root/vendor/LOCK.tsv"

(
  cd "$package_root"
  find . -type f ! -name BUNDLE-SHA256SUMS -print | LC_ALL=C sort | while IFS= read -r file; do
    printf '%s  %s\n' "$(sha256_file "$file")" "$file"
  done > BUNDLE-SHA256SUMS
)
"$package_root/scripts/verify-checksums.sh" "$package_root/BUNDLE-SHA256SUMS" "$package_root"

archive=$dist/$package.tar.gz
checksum=$archive.sha256
rm -f "$archive" "$checksum"
python3 "$repo_root/scripts/write-reproducible-archive.py" "$package_root" "$archive" "$source_epoch"
printf '%s  ./%s\n' "$(sha256_file "$archive")" "$(basename -- "$archive")" > "$checksum"
chmod 0644 "$archive" "$checksum"
printf 'Created %s\nCreated %s\n' "$archive" "$checksum"
