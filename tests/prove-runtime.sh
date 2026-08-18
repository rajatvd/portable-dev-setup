#!/usr/bin/env bash
set -euo pipefail

repo_root=${1:-$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)}
proof_root=$(mktemp -d "${TMPDIR:-/tmp}/portable-dev-setup-runtime-proof.XXXXXX")
trap 'rm -rf "$proof_root"' EXIT

fail() {
  printf 'RUNTIME PROOF FAILED: %s\n' "$*" >&2
  exit 1
}

run_bounded() {
  local seconds=$1
  local stdout_file=$2
  local stderr_file=$3
  shift 3
  "$@" > "$stdout_file" 2> "$stderr_file" &
  local command_pid=$!
  local deadline=$((SECONDS + seconds))
  local timed_out=false
  while kill -0 "$command_pid" 2>/dev/null; do
    if (( SECONDS >= deadline )); then
      timed_out=true
      kill -TERM "$command_pid" 2>/dev/null || true
      break
    fi
    sleep 1
  done
  local status
  set +e
  wait "$command_pid"
  status=$?
  set -e
  if [[ "$timed_out" == true || "$status" -ne 0 ]]; then
    cat "$stdout_file" >&2 || true
    cat "$stderr_file" >&2 || true
    [[ "$timed_out" == false ]] || fail "bounded command exceeded ${seconds}s"
    fail "bounded command exited with status $status"
  fi
}

case "$(uname -s)" in
  Darwin) profile=macos ;;
  Linux) profile=linux ;;
  *) fail 'proof requires macOS or Linux' ;;
esac

home=$proof_root/home
config_home=$home/xdg-config
data_home=$home/xdg-data
state_home=$home/xdg-state
mkdir -p "$config_home/nvim" "$data_home/portable-dev-setup" "$data_home/nvim/site/pack/portable"
printf 'old zshrc\n' > "$home/.zshrc"
printf 'old prompt\n' > "$home/.p10k.zsh"
printf 'old config\n' > "$config_home/nvim/old.txt"
printf 'old runtime\n' > "$data_home/portable-dev-setup/old.txt"
printf 'old plugins\n' > "$data_home/nvim/site/pack/portable/old.txt"
printf 'export PORTABLE_LOCAL_SEAM=loaded\n' > "$home/.zshrc.local"

HOME="$home" \
XDG_CONFIG_HOME="$config_home" \
XDG_DATA_HOME="$data_home" \
XDG_STATE_HOME="$state_home" \
  "$repo_root/install.sh" --profile "$profile" > "$proof_root/install.out"

grep -Fq 'Pinned Neovim plugins were provisioned from local snapshots.' "$proof_root/install.out" || fail 'plugin provisioning was not reported'
grep -Fq 'export PORTABLE_LOCAL_SEAM=loaded' "$home/.zshrc.local" || fail 'machine-local seam was changed'

backup_parent=$state_home/portable-dev-setup/backups
set -- "$backup_parent"/*
[[ $# -eq 1 && -d "$1" ]] || fail 'expected one backup directory'
backup=$1
[[ -f "$backup/home/.zshrc" ]] || fail 'zshrc backup is missing'
[[ -f "$backup/config/nvim/old.txt" ]] || fail 'Neovim backup is missing'
[[ -f "$backup/data/nvim/site/pack/portable/old.txt" ]] || fail 'plugin backup is missing'

run_bounded 30 "$proof_root/zsh.out" "$proof_root/zsh.err" \
  env HOME="$home" XDG_CONFIG_HOME="$config_home" XDG_DATA_HOME="$data_home" XDG_STATE_HOME="$state_home" ZDOTDIR="$home" \
  zsh -dfc 'source "$HOME/.zshrc"; [[ "$PORTABLE_LOCAL_SEAM" == loaded ]]; [[ "$POWERLEVEL9K_DISABLE_GITSTATUS" == true ]]; [[ -n "${functions[prompt_powerlevel10k_setup]-}" ]]; alias zshconfig >/dev/null; alias nvconfig >/dev/null; print "zsh runtime assertions passed"'
grep -Fq 'zsh runtime assertions passed' "$proof_root/zsh.out" || fail 'zsh assertions did not finish'

lua_assertions=$repo_root/tests/nvim_assertions.lua
nvim_bin=$(command -v nvim)
mkdir -p "$proof_root/nvim-bin"
ln -s "$nvim_bin" "$proof_root/nvim-bin/nvim"
run_bounded 30 "$proof_root/nvim.out" "$proof_root/nvim.err" \
  env HOME="$home" XDG_CONFIG_HOME="$config_home" XDG_DATA_HOME="$data_home" XDG_STATE_HOME="$state_home" \
  PATH="$proof_root/nvim-bin" \
  nvim --headless --cmd 'set shortmess+=I' "+lua dofile([[$lua_assertions]])" +qa
if ! grep -Fq 'Expanded Neovim runtime assertions passed.' "$proof_root/nvim.out" && \
   ! grep -Fq 'Expanded Neovim runtime assertions passed.' "$proof_root/nvim.err"; then
  cat "$proof_root/nvim.out" >&2 || true
  cat "$proof_root/nvim.err" >&2 || true
  fail 'Neovim assertions did not finish'
fi

printf 'Installed runtime proof passed on %s with %s.\n' "$(uname -s)" "$(nvim --version | sed -n '1p')"
