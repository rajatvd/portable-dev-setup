#!/usr/bin/env bash
set -euo pipefail

repo_root=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
test_root=$(mktemp -d "${TMPDIR:-/tmp}/portable-dev-setup-tests.XXXXXX")
trap 'rm -rf "$test_root"' EXIT

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

assert_file() {
  [[ -f "$1" ]] || fail "expected file: $1"
}

assert_absent() {
  [[ ! -e "$1" && ! -L "$1" ]] || fail "expected absent path: $1"
}

assert_contains() {
  grep -Fq -- "$2" "$1" || fail "expected $1 to contain: $2"
}

make_fake_host() {
  local kernel=$1
  local bin_dir=$2
  mkdir -p "$bin_dir"
  cat > "$bin_dir/uname" <<EOF_UNAME
#!/bin/sh
printf '%s\\n' '$kernel'
EOF_UNAME
  cat > "$bin_dir/nvim" <<'EOF_NVIM'
#!/bin/sh
exit 0
EOF_NVIM
  chmod 755 "$bin_dir/uname" "$bin_dir/nvim"
}

snapshot() {
  local root=$1
  (
    cd "$root"
    find . -type f -print | LC_ALL=C sort | while IFS= read -r file; do
      cksum "$file"
    done
  )
}

check_pins() {
  local path commit kind url license actual staged
  while IFS=$'\t' read -r path commit kind url license; do
    [[ -n "$path" && ${path:0:1} != '#' ]] || continue
    [[ "$url" == https://github.com/* ]] || fail "non-public dependency URL: $url"
    actual=$(git -C "$repo_root/$path" rev-parse HEAD) || fail "uninitialized submodule: $path"
    [[ "$actual" == "$commit" ]] || fail "$path checkout is $actual; expected $commit"
    staged=$(git -C "$repo_root" ls-files --stage "$path" | awk '{print $2}')
    [[ "$staged" == "$commit" ]] || fail "$path gitlink is $staged; expected $commit"
    [[ -f "$repo_root/$path/$license" ]] || fail "missing license: $path/$license"
  done < "$repo_root/vendor/LOCK.tsv"
}

run_check_and_dry_run() {
  local kernel=$1
  local profile=$2
  local label=$3
  local root=$test_root/modes-$profile
  local home=$root/home
  local bin_dir=$root/bin
  local before after
  mkdir -p "$home"
  printf 'sentinel\n' > "$home/sentinel"
  make_fake_host "$kernel" "$bin_dir"
  before=$(snapshot "$home")
  HOME="$home" PATH="$bin_dir:$PATH" "$repo_root/install.sh" --check --profile "$profile" > "$root/check.out"
  HOME="$home" PATH="$bin_dir:$PATH" "$repo_root/install.sh" --dry-run --profile "$profile" > "$root/dry.out"
  after=$(snapshot "$home")
  [[ "$before" == "$after" ]] || fail "$profile check or dry-run changed HOME"
  assert_contains "$root/check.out" "$label profile is ready"
  assert_contains "$root/dry.out" "Dry run for $label ($kernel); no files will be changed."
}

run_install() {
  local kernel=$1
  local profile=$2
  local label=$3
  local root=$test_root/install-$profile
  local home=$root/home
  local config_home=$home/xdg-config
  local data_home=$home/xdg-data
  local state_home=$home/xdg-state
  local bin_dir=$root/bin
  local backup_parent backup

  mkdir -p "$config_home/nvim" "$data_home/portable-dev-setup" "$data_home/nvim/site/pack/portable" "$bin_dir"
  printf 'old zshrc\n' > "$home/.zshrc"
  printf 'old prompt\n' > "$home/.p10k.zsh"
  printf 'old nvim\n' > "$config_home/nvim/old.txt"
  printf 'old shell runtime\n' > "$data_home/portable-dev-setup/old.txt"
  printf 'old plugin runtime\n' > "$data_home/nvim/site/pack/portable/old.txt"
  printf 'local seam\n' > "$home/.zshrc.local"
  make_fake_host "$kernel" "$bin_dir"

  HOME="$home" \
  XDG_CONFIG_HOME="$config_home" \
  XDG_DATA_HOME="$data_home" \
  XDG_STATE_HOME="$state_home" \
  PATH="$bin_dir:$PATH" \
    "$repo_root/install.sh" --profile "$profile" > "$root/install.out"

  assert_contains "$root/install.out" "Installed the shared payload for the $label profile."
  cmp "$repo_root/config/zshrc" "$home/.zshrc" >/dev/null || fail "$profile zshrc differs"
  cmp "$repo_root/config/p10k.zsh" "$home/.p10k.zsh" >/dev/null || fail "$profile prompt config differs"
  assert_file "$config_home/nvim/init.vim"
  assert_file "$data_home/portable-dev-setup/oh-my-zsh/oh-my-zsh.sh"
  assert_file "$data_home/portable-dev-setup/oh-my-zsh/custom/themes/powerlevel10k/powerlevel10k.zsh-theme"
  assert_file "$data_home/portable-dev-setup/oh-my-zsh/custom/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh"
  assert_file "$data_home/portable-dev-setup/oh-my-zsh/custom/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
  local plugin_file
  for plugin_file in \
    vim-commentary/plugin/commentary.vim \
    vim-surround/plugin/surround.vim \
    vim-fugitive/plugin/fugitive.vim \
    nvim-cmp/lua/cmp/init.lua \
    cmp-nvim-lsp/lua/cmp_nvim_lsp/init.lua \
    cmp-buffer/lua/cmp_buffer/init.lua \
    cmp-path/lua/cmp_path/init.lua \
    luasnip/lua/luasnip/init.lua \
    cmp_luasnip/lua/cmp_luasnip/init.lua \
    plenary.nvim/lua/plenary/init.lua \
    telescope.nvim/lua/telescope/init.lua \
    oil.nvim/lua/oil/init.lua \
    leap.nvim/lua/leap/init.lua \
    which-key.nvim/lua/which-key/init.lua \
    nvim-web-devicons/lua/nvim-web-devicons.lua; do
    assert_file "$data_home/nvim/site/pack/portable/start/$plugin_file"
  done
  assert_contains "$home/.zshrc.local" 'local seam'
  assert_absent "$config_home/nvim/.git"
  if find "$data_home/nvim/site/pack/portable" -name .git -print | grep -q .; then
    fail "$profile installed plugin Git metadata"
  fi
  assert_absent "$data_home/nvim/site/pack/portable/start/luasnip/deps"

  backup_parent=$state_home/portable-dev-setup/backups
  set -- "$backup_parent"/*
  [[ $# -eq 1 && -d "$1" ]] || fail "$profile expected one backup directory"
  backup=$1
  assert_contains "$backup/home/.zshrc" 'old zshrc'
  assert_contains "$backup/home/.p10k.zsh" 'old prompt'
  assert_contains "$backup/config/nvim/old.txt" 'old nvim'
  assert_contains "$backup/data/portable-dev-setup/old.txt" 'old shell runtime'
  assert_contains "$backup/data/nvim/site/pack/portable/old.txt" 'old plugin runtime'

  printf '%s\n' "$root"
}

printf '%s\n' '[1/6] syntax and exact public pins'
bash -n "$repo_root/install.sh" "$repo_root/scripts/build-bundle.sh" "$repo_root/scripts/verify-checksums.sh"
bash -n "$repo_root/tests/test.sh" "$repo_root/tests/prove-runtime.sh" "$repo_root/tests/prove-bundle.sh"
zsh -n "$repo_root/config/zshrc" "$repo_root/config/p10k.zsh"
check_pins
[[ "$(git -C "$repo_root" ls-files --stage nvim/init.vim | awk '{print $1}')" == 100644 ]] || fail 'Neovim config is not vendored as ordinary files'

printf '%s\n' '[2/6] macOS and Linux check/dry-run profiles'
run_check_and_dry_run Darwin macos macOS
run_check_and_dry_run Linux linux Linux

printf '%s\n' '[3/6] backup-before-replace installs'
mac_root=$(run_install Darwin macos macOS)
linux_root=$(run_install Linux linux Linux)

printf '%s\n' '[4/6] one shared payload'
cmp "$mac_root/home/.zshrc" "$linux_root/home/.zshrc" >/dev/null || fail 'profiles installed different zshrc files'
cmp "$mac_root/home/.p10k.zsh" "$linux_root/home/.p10k.zsh" >/dev/null || fail 'profiles installed different prompt files'
diff -r "$mac_root/home/xdg-config/nvim" "$linux_root/home/xdg-config/nvim" >/dev/null || fail 'profiles installed different Neovim configs'
diff -r "$mac_root/home/xdg-data/portable-dev-setup" "$linux_root/home/xdg-data/portable-dev-setup" >/dev/null || fail 'profiles installed different shell runtimes'
diff -r "$mac_root/home/xdg-data/nvim/site/pack/portable" "$linux_root/home/xdg-data/nvim/site/pack/portable" >/dev/null || fail 'profiles installed different plugin runtimes'

printf '%s\n' '[5/6] rejection behavior'
unsupported=$test_root/unsupported
mkdir -p "$unsupported/home"
make_fake_host FreeBSD "$unsupported/bin"
if HOME="$unsupported/home" PATH="$unsupported/bin:$PATH" "$repo_root/install.sh" --check > "$unsupported/out" 2> "$unsupported/err"; then
  fail 'unsupported kernel was accepted'
fi
assert_contains "$unsupported/err" 'unsupported kernel: FreeBSD'
if HOME="$unsupported/home" PATH="$unsupported/bin:$PATH" "$repo_root/install.sh" --check --profile= > "$unsupported/empty.out" 2> "$unsupported/empty.err"; then
  fail 'empty profile was accepted'
fi
assert_contains "$unsupported/empty.err" '--profile requires macos or linux'

mismatch=$test_root/mismatch
mkdir -p "$mismatch/home"
make_fake_host Linux "$mismatch/bin"
if HOME="$mismatch/home" PATH="$mismatch/bin:$PATH" "$repo_root/install.sh" --check --profile macos > "$mismatch/out" 2> "$mismatch/err"; then
  fail 'mismatched profile was accepted'
fi
assert_contains "$mismatch/err" 'profile macos does not match uname kernel Linux'

printf '%s\n' '[6/6] package safety shape'
[[ "$(grep -c '\.zshrc\.local' "$repo_root/config/zshrc")" -eq 1 ]] || fail 'unexpected machine-local seam count'
if grep -RInE 'curl|wget|PlugInstall|git[[:space:]]+clone' "$repo_root/nvim" "$repo_root/install.sh" > "$test_root/network-hits"; then
  cat "$test_root/network-hits" >&2
  fail 'runtime or installer contains a network bootstrap path'
fi
if grep -RInEi '(mason|copilot|octo|orgmode|thesis|ipython|tmux|mpv|rsync|cuda|treesitter)' "$repo_root/nvim" > "$test_root/excluded-feature-hits"; then
  cat "$test_root/excluded-feature-hits" >&2
  fail 'excluded personal, host-specific, account, or parser behavior is present'
fi
if grep -InE 'sudo[[:space:]]|brew[[:space:]]+(install|update)|apt(-get)?[[:space:]]|yum[[:space:]]|dnf[[:space:]]|pacman[[:space:]]|cmake[[:space:]]|ninja[[:space:]]' \
  "$repo_root/install.sh" > "$test_root/host-mutation-hits"; then
  cat "$test_root/host-mutation-hits" >&2
  fail 'installer contains host mutation commands'
fi
if git -C "$repo_root" grep -nIE '(/home/[[:alnum:]_-]+|/Users/[[:alnum:]_-]+|git@github\.com:|BEGIN [A-Z ]*PRIVATE KEY|xox[baprs]-[A-Za-z0-9-]+|AKIA[0-9A-Z]{16})' -- ':!tests/test.sh' > "$test_root/public-hits"; then
  cat "$test_root/public-hits" >&2
  fail 'tracked first-party files contain a private path or credential-shaped value'
fi
[[ ! -d "$repo_root/file_storage" ]] || fail 'report storage must not be in the package'

printf '%s\n' 'All structural tests passed.'
