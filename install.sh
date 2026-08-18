#!/usr/bin/env bash
set -euo pipefail

case "${BASH_SOURCE[0]}" in
  */*) script_dir=${BASH_SOURCE[0]%/*} ;;
  *) script_dir=. ;;
esac
repo_root=$(CDPATH= cd -- "$script_dir" && pwd)
mode=install
requested_profile=
profile=
profile_label=
kernel=
staging_root=
backup_root=

usage() {
  cat <<'USAGE'
Usage: ./install.sh [--check | --dry-run] [--profile macos|linux]

  --check             verify host requirements and exact dependency snapshots
  --dry-run           verify readiness and print the installation plan
  --profile PROFILE   require the macOS or Linux profile explicitly
USAGE
}

fail() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

cleanup() {
  [[ -z "$staging_root" || ! -d "$staging_root" ]] || rm -rf "$staging_root"
}
trap cleanup EXIT

set_mode() {
  [[ "$mode" == install ]] || fail 'choose only one of --check or --dry-run'
  mode=$1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --check)
      set_mode check
      shift
      ;;
    --dry-run)
      set_mode dry-run
      shift
      ;;
    --profile)
      [[ $# -ge 2 ]] || fail '--profile requires macos or linux'
      [[ -z "$requested_profile" ]] || fail 'specify --profile only once'
      requested_profile=$2
      shift 2
      ;;
    --profile=*)
      [[ -z "$requested_profile" ]] || fail 'specify --profile only once'
      requested_profile=${1#--profile=}
      [[ -n "$requested_profile" ]] || fail '--profile requires macos or linux'
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      usage >&2
      exit 2
      ;;
  esac
done

require_command() {
  command -v "$1" >/dev/null 2>&1 || fail "missing required command: $1"
}

select_profile() {
  local detected
  case "$requested_profile" in
    ''|macos|linux) ;;
    *) fail "unsupported profile: $requested_profile (expected macos or linux)" ;;
  esac

  require_command uname
  kernel=$(uname -s 2>/dev/null) || fail 'unable to identify the host kernel'
  case "$kernel" in
    Darwin) detected=macos ;;
    Linux) detected=linux ;;
    *) fail "unsupported kernel: $kernel (expected Darwin or Linux)" ;;
  esac
  if [[ -n "$requested_profile" && "$requested_profile" != "$detected" ]]; then
    fail "profile $requested_profile does not match uname kernel $kernel"
  fi
  profile=${requested_profile:-$detected}
  case "$profile" in
    macos) profile_label=macOS ;;
    linux) profile_label=Linux ;;
  esac
}

check_host() {
  local name
  for name in awk cat chmod cp date dirname find git grep mkdir mktemp mv nvim rm sed sort zsh; do
    require_command "$name"
  done
  zsh -fc 'autoload -Uz is-at-least; is-at-least 5.1' || fail 'zsh 5.1 or newer is required'
  nvim --clean --headless -u NONE "+if !has('nvim-0.9') | cquit 1 | endif" +qa >/dev/null 2>&1 || \
    fail 'Neovim 0.9 or newer is required'
}

check_dependencies() {
  local path commit kind url license actual state revision_file
  while IFS=$'\t' read -r path commit kind url license; do
    [[ -n "$path" && ${path:0:1} != '#' ]] || continue
    [[ -d "$repo_root/$path" ]] || fail "missing dependency snapshot: $path (use a recursive clone)"
    if actual=$(git -C "$repo_root/$path" rev-parse HEAD 2>/dev/null); then
      [[ "$actual" == "$commit" ]] || fail "$path is at $actual; expected $commit"
      state=$(git -C "$repo_root/$path" status --porcelain --untracked-files=all)
      [[ -z "$state" ]] || fail "dependency snapshot has local changes: $path"
    else
      revision_file=$repo_root/$path/.portable-revision
      [[ -f "$revision_file" ]] || fail "cannot verify dependency snapshot: $path"
      actual=$(cat "$revision_file")
      [[ "$actual" == "$commit" ]] || fail "$path bundle snapshot is at $actual; expected $commit"
    fi
    [[ -f "$repo_root/$path/$license" ]] || fail "missing third-party license: $path/$license"
  done < "$repo_root/vendor/LOCK.tsv"
}

verify_bundle_if_present() {
  if [[ -f "$repo_root/BUNDLE-SHA256SUMS" ]]; then
    "$repo_root/scripts/verify-checksums.sh" "$repo_root/BUNDLE-SHA256SUMS" "$repo_root" >/dev/null
  fi
}

copy_snapshot() {
  local source=$1
  local destination=$2
  mkdir -p "$destination"
  cp -R "$source"/. "$destination"/
  rm -rf "$destination/.git" "$destination/.portable-revision"
}

select_profile
check_host
verify_bundle_if_present
check_dependencies

if [[ "$mode" == check ]]; then
  printf '%s profile is ready; host requirements and exact snapshots passed.\n' "$profile_label"
  exit 0
fi

home=${HOME:?HOME must be set}
config_home=${XDG_CONFIG_HOME:-$home/.config}
data_home=${XDG_DATA_HOME:-$home/.local/share}
state_home=${XDG_STATE_HOME:-$home/.local/state}
runtime_target=$data_home/portable-dev-setup
nvim_target=$config_home/nvim
nvim_pack_target=$data_home/nvim/site/pack/portable
zshrc_target=$home/.zshrc
p10k_target=$home/.p10k.zsh

if [[ "$mode" == dry-run ]]; then
  cat <<EOF_PLAN
Dry run for $profile_label ($kernel); no files will be changed.
Would move existing managed targets beneath:
  $state_home/portable-dev-setup/backups/<UTC timestamp>-<process id>/
Would install the shared payload to:
  $zshrc_target
  $p10k_target
  $nvim_target
  $runtime_target
  $nvim_pack_target
Would leave this machine-local extension untouched:
  $home/.zshrc.local
All dependency snapshots are local; installation performs no network access.
EOF_PLAN
  exit 0
fi

umask 022
staging_root=$(mktemp -d "${TMPDIR:-/tmp}/portable-dev-setup.XXXXXX")
mkdir -p "$staging_root/runtime/oh-my-zsh/custom/themes"
mkdir -p "$staging_root/runtime/oh-my-zsh/custom/plugins"
mkdir -p "$staging_root/nvim-pack/start"

copy_snapshot "$repo_root/vendor/oh-my-zsh" "$staging_root/runtime/oh-my-zsh"
copy_snapshot "$repo_root/vendor/powerlevel10k" "$staging_root/runtime/oh-my-zsh/custom/themes/powerlevel10k"
copy_snapshot "$repo_root/vendor/zsh-autosuggestions" "$staging_root/runtime/oh-my-zsh/custom/plugins/zsh-autosuggestions"
copy_snapshot "$repo_root/vendor/zsh-syntax-highlighting" "$staging_root/runtime/oh-my-zsh/custom/plugins/zsh-syntax-highlighting"
copy_snapshot "$repo_root/nvim" "$staging_root/nvim"

while IFS=$'\t' read -r path commit kind url license; do
  [[ -n "$path" && ${path:0:1} != '#' ]] || continue
  [[ "$kind" == nvim ]] || continue
  name=${path##*/}
  copy_snapshot "$repo_root/$path" "$staging_root/nvim-pack/start/$name"
done < "$repo_root/vendor/LOCK.tsv"

cp "$repo_root/config/zshrc" "$staging_root/zshrc"
cp "$repo_root/config/p10k.zsh" "$staging_root/p10k.zsh"

backup_root=$state_home/portable-dev-setup/backups/$(date -u +%Y%m%dT%H%M%SZ)-$$
backed_up=false

backup_existing() {
  local source=$1
  local relative=$2
  if [[ -e "$source" || -L "$source" ]]; then
    mkdir -p "$backup_root/$(dirname -- "$relative")"
    mv "$source" "$backup_root/$relative"
    backed_up=true
  fi
}

backup_existing "$zshrc_target" home/.zshrc
backup_existing "$p10k_target" home/.p10k.zsh
backup_existing "$nvim_target" config/nvim
backup_existing "$runtime_target" data/portable-dev-setup
backup_existing "$nvim_pack_target" data/nvim/site/pack/portable

mkdir -p "$(dirname -- "$zshrc_target")" "$(dirname -- "$p10k_target")"
mkdir -p "$(dirname -- "$nvim_target")" "$(dirname -- "$runtime_target")" "$(dirname -- "$nvim_pack_target")"
mv "$staging_root/zshrc" "$zshrc_target"
mv "$staging_root/p10k.zsh" "$p10k_target"
mv "$staging_root/nvim" "$nvim_target"
mv "$staging_root/runtime" "$runtime_target"
mv "$staging_root/nvim-pack" "$nvim_pack_target"
chmod 0644 "$zshrc_target" "$p10k_target"

printf 'Installed the shared payload for the %s profile.\n' "$profile_label"
if [[ "$backed_up" == true ]]; then
  printf 'Previous managed targets were moved to %s\n' "$backup_root"
fi
printf 'Pinned Neovim plugins were provisioned from local snapshots.\n'
printf 'Machine-local settings remain in %s.\n' "$home/.zshrc.local"
