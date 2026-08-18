# Portable zsh and Neovim setup

A host-neutral zsh, Powerlevel10k, and source-backed Neovim package for macOS and Linux. Both profiles install the same payload; profile selection only validates `uname -s` and makes the target explicit.

## What it installs

- `~/.zshrc` and `~/.p10k.zsh`
- `${XDG_CONFIG_HOME:-$HOME/.config}/nvim`
- Oh My Zsh, Powerlevel10k, and zsh plugins under `${XDG_DATA_HOME:-$HOME/.local/share}/portable-dev-setup`
- exact Neovim plugin snapshots under `${XDG_DATA_HOME:-$HOME/.local/share}/nvim/site/pack/portable`

Existing managed targets are moved first to `${XDG_STATE_HOME:-$HOME/.local/state}/portable-dev-setup/backups/<timestamp>-<process-id>/`. The installer never changes the login shell and never touches `~/.zshrc.local`; that ignored file is the only machine-local extension point.

## Neovim features

The configuration preserves the portable editor behavior behind this distribution:

- relative and absolute line numbers, four-space indentation, persistent XDG undo, wrapped text, centered scrolling, quickfix navigation, and an 88-column guide;
- source-backed save, escape, window, line-motion, tag, command-line, terminal, and quickfix mappings;
- native Neovim LSP startup for Python, C, C++, and Lua;
- `nvim-cmp` with LSP, buffer, path, and LuaSnip completion sources;
- Telescope with plenary and a file-finder mapping;
- Oil as the directory editor;
- Leap motions;
- Which-Key and nvim-web-devicons;
- vim-fugitive, vim-commentary, and the source-backed vim-surround mappings.

No Mason, Treesitter, Copilot, Octo, account integration, project state, calendar/org tooling, remote-sync workflow, media/render workflow, or host scheduler/toolchain configuration is included.

### Language-server boundary

Language servers are optional host prerequisites, never managed dependencies:

- Python: `pyright-langserver`, falling back to `pylsp`
- C and C++: `clangd`
- Lua: `lua-language-server`

The configuration checks `PATH` when a matching filetype opens. If no server executable is present, startup remains clean and no client is started. The installer and Neovim configuration never install or download a language server.

## Requirements

The host must already provide:

- Bash, Git, Make, and standard POSIX userland tools
- zsh 5.1 or newer
- Neovim 0.10 or newer
- a Nerd Font for the intended terminal

The installer does not elevate privileges, invoke a host package manager, build software, access credentials, or use the network. Dependencies are exact public snapshots. Neovim plugins are copied during installation, so the first editor launch cannot trigger a download. Powerlevel10k's optional gitstatus helper is disabled; VCS prompt information uses the built-in zsh backend without fetching a binary.

## Clone and install

After publication, clone the repository's ordinary HTTPS URL with its public submodules:

```sh
git clone --recurse-submodules https://github.com/<owner>/portable-dev-setup.git
cd portable-dev-setup
```

Then choose an explicit target:

```sh
make check-macos
make dry-run-macos
make install-macos
```

or:

```sh
make check-linux
make dry-run-linux
make install-linux
```

`make check`, `make dry-run`, and `make install` select `macos` for `Darwin` and `linux` for `Linux`. An explicit profile must match the detected kernel.

## Offline bundle

From a clean recursive clone:

```sh
make bundle
```

This creates `dist/portable-dev-setup-1.0.0.tar.gz` and an outer SHA-256 file. The archive also contains `BUNDLE-SHA256SUMS`, covering every included file. It materializes all required shell and Neovim snapshots, their licenses, and the complete runtime payload.

After downloading both files, verify and install without network access:

```sh
shasum -a 256 -c portable-dev-setup-1.0.0.tar.gz.sha256
tar -xzf portable-dev-setup-1.0.0.tar.gz
cd portable-dev-setup-1.0.0
./scripts/verify-checksums.sh BUNDLE-SHA256SUMS .
make install
```

On Linux, `sha256sum -c` can be used for the outer checksum.

## Proofs

```sh
make test          # structure, pins, profiles, backups, and shared payload
make prove         # isolated install plus bounded real zsh/Neovim assertions
make prove-bundle  # checksum, fresh extraction, isolated reinstall, and startup proof
```

The pinned Linux and macOS jobs assert source-backed settings and mappings, every included plugin module or command, completion sources, native LSP initialization with all server executables absent, clean exit, and the full extracted-bundle reinstall path.

## Licensing

First-party files are MIT licensed. Third-party source remains under its original terms; exact commits and license custody are listed in [THIRD_PARTY_LICENSES.md](THIRD_PARTY_LICENSES.md).
