# Portable zsh and Neovim setup

A host-neutral zsh, Powerlevel10k, and Neovim package for macOS and Linux. Both profiles install the same payload; profile selection only validates `uname -s` and makes the target explicit.

## What it installs

- `~/.zshrc` and `~/.p10k.zsh`
- `${XDG_CONFIG_HOME:-$HOME/.config}/nvim`
- Oh My Zsh, Powerlevel10k, and zsh plugins under `${XDG_DATA_HOME:-$HOME/.local/share}/portable-dev-setup`
- exact Neovim plugin snapshots under `${XDG_DATA_HOME:-$HOME/.local/share}/nvim/site/pack/portable`

Existing managed targets are moved first to `${XDG_STATE_HOME:-$HOME/.local/state}/portable-dev-setup/backups/<timestamp>-<process-id>/`. The installer never changes the login shell and never touches `~/.zshrc.local`; that ignored file is the only machine-local extension point.

## Requirements

The host must already provide:

- Bash, Git, Make, and standard POSIX userland tools
- zsh 5.1 or newer
- Neovim 0.9 or newer
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

This creates `dist/portable-dev-setup-1.0.0.tar.gz` and an outer SHA-256 file. The archive also contains `BUNDLE-SHA256SUMS`, covering every included file. It materializes all submodules, including licenses and the complete shell and Neovim runtime payload.

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
make prove         # isolated install plus bounded real zsh/Neovim startup assertions
make prove-bundle  # checksum, fresh extraction, isolated install, and startup proof
```

The GitHub Actions workflow runs all three proofs as separate pinned Linux and macOS jobs. Neovim assertions cover startup completion, settings, mappings, all three pinned plugins, and clean headless exit.

## Licensing

First-party files are MIT licensed. Third-party source remains under its original terms; exact commits and license custody are listed in [THIRD_PARTY_LICENSES.md](THIRD_PARTY_LICENSES.md).
