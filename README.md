# Portable zsh and Neovim setup

A host-neutral zsh, Powerlevel10k, and source-backed Neovim package for macOS and Linux. Both profiles install the same payload; profile selection only validates `uname -s` and makes the target explicit.

## What it installs

- `~/.zshrc` and `~/.p10k.zsh`
- `${XDG_CONFIG_HOME:-$HOME/.config}/nvim`
- Oh My Zsh, Powerlevel10k, and zsh plugins under `${XDG_DATA_HOME:-$HOME/.local/share}/portable-dev-setup`
- exact Neovim plugin and Base16 Atelier Estuary theme snapshots under `${XDG_DATA_HOME:-$HOME/.local/share}/nvim/site/pack/portable`

Existing managed targets are moved first to `${XDG_STATE_HOME:-$HOME/.local/state}/portable-dev-setup/backups/<timestamp>-<process-id>/`. The installer never changes the login shell and never touches `~/.zshrc.local`; that ignored file remains the shell-local extension point. Neovim has a separate optional `nvim-local.lua` table outside its managed directory (see below).

## Neovim features

The payload preserves a source-backed **Vimscript/Lua hybrid**, including its load-order and filetype overrides:

- Base16 Atelier Estuary (with optional Gruvbox Material, Gruvbox and Rainglow palettes), Airline/tabline, four-column tabs, case-sensitive search with `smartcase`, persistent XDG undo, wrapped text, and an 88-column guide. Python's ftplugin uses spaces; Oil disables wrap locally; TeX/Markdown reassert it.
- Save/escape/window/quickfix/tag motions, explicit clipboard yank (`<leader><leader>y`, `Y<leader><leader>`), and fzf-aware terminal escapes. Leader and local leader are Space.
- Telescope (files, snippets, media, and configured Org pickers), Oil, Leap plus parser-backed AST motion, Which-Key, colorizer, Fugitive status and explicit push (`<leader>gp`), commentary, surround, root detection, textobjects, auto-pairs, Tagbar and vim-test.
- `nvim-cmp`, LuaSnip, friendly/LaTeX snippet collections and VSCode lazy loading. Tab falls back when no completion/snippet action applies. Mode-specific mapping declarations are retained; **no `cmp.setup.cmdline` session is configured**.
- Treesitter highlighting, textobjects, definition peeks and playground with **no parser downloads at startup**. Provision platform-compatible parsers on runtimepath; `parser_path` can point to a separate runtime directory. The plugin lockfile records its grammar revisions; Org uses grammar 1.3.4 or newer. `:PortableHealth` distinguishes missing parsers from disabled integrations.
- VimTeX/latexmk and Autoformat policies; host-provided viewers/formatters. C/C++/CUDA build/clean/run/error-list keys (`<leader>m[dcre]`) and Python docstring/textobject/render keys are buffer-local and cleaned up on filetype changes.
- Terminal toggle (`<leader>r`, `<leader><leader>R`), messages (`<leader>mb`), breakpoints (`<leader>id`), terminal selection (`:SendHere`, `:SendTo`), shape/length operators, default-argument sending and configured REPL startup.
- Optional Copilot/Octo/Git completion, Org/capture/calendar, task quickfix/floating views, marked-text-block scanning (`:ThesisAI`), render/watch, notebook conversion, Markdown preview and remote sync. These are retained integrations, **not bundled accounts, documents or backends**.

### Host dependencies and explicit local configuration

Run `:PortableHealth` for configuration/dependency status. No credentials, language servers, parsers, interpreters, viewer binaries, clipboard providers or toolchains are installed by Neovim or the installer.

Language-server presets use host executables: Python starts **Pyright and Ruff together** when available (Ruff supplies linting/import organization); C/C++/CUDA use clangd; Lua uses lua-language-server with neodev; TeX/Bib use texlab; Vim uses vim-language-server; Markdown uses marksman; HTML uses vscode-html-language-server; Mojo uses mojo-lsp-server. Missing executables are recorded in `b:portable_lsp_status`. The format key excludes Pyright, uses native formatting where supported except Texlab, and otherwise invokes Autoformat. There is no format-on-save hook or Mason bootstrap.

`Files`, `Buffers`, `History`, `Rg`, `RG`, and `GGrep` retain fzf previews/history/widget bindings. They require host **fzf >= 0.56.0**; file/grep search additionally requires ripgrep, and tags need ctags. No fzf binary installer is invoked by these guarded entrypoints. `MediaFiles` needs fd/chafa. Python docstrings need `doq`; builds need make; LaTeX compilation needs latexmk and a toolchain; formatting needs black/prettier/latexindent as appropriate.

Copy `nvim/local.example.lua` to `${XDG_CONFIG_HOME:-$HOME/.config}/nvim-local.lua`, or set **`NVIM_PORTABLE_LOCAL`** to one trusted Lua file returning a table. The default file is outside the managed Neovim directory and is preserved by reinstall. Never add its contents to Git. With no local configuration, core editing works offline; attempting a configured-only workflow gives a diagnostic, not a silent no-op. Invalid local files produce a redacted diagnostic without echoing their source or values.

Enable only the integrations you intend to use. Account packages live under `pack/portable/opt` and are not sourced until explicitly enabled. Enabling Copilot authorizes its provider and gives insert Ctrl-J to Copilot instead of cmp; its source-style `markdown=true` setting does **not** disable other filetypes. Octo's issue/PR/review context actions are retained. Authentication remains host/provider-owned; no authentication occurs in installation/tests.

Org requires explicit agenda/notes paths and a provisioned parser; capture templates, scratch/calendar paths, timezone parsing/formatting and synchronization backends remain local. Task providers return quickfix items or Markdown. Marked-block scanning requires explicit markers and a root. REPL startup takes executable argv and optional startup lines, not a guessed activation alias/session. Rendering takes argv/output providers, interrupts its previous owned render/player when repeated, and starts the player only after a successful current render. It does not interrupt unrelated sessions. Remote sync takes explicit local/remote paths and runs only on `ARsyncDown`, `ARsyncUp`, or `ARsyncUpDelete` (the latter deletes extraneous destination files). No project sync files are discovered or sourced automatically.

### Compatibility and deliberate boundaries

Existing dependency pins are unchanged. Added snapshots use a fixed Neovim 0.10 compatibility baseline; the Treesitter textobject dependency uses its matching legacy API branch, and the Org picker uses the maintained fork compatible with the Org API. Source defects repaired separately from privacy adaptations include terminal key escaping, the snippet update-event typo, first-terminal creation, unsafe shell interpolation, nil-environment REPL startup and cached/global filetype mappings. Airline changes the authored `showtabline=4` to an effective `2`; the earlier value is not forced back after plugin startup.

Unknown historical plugin defaults, personal snippet bodies and local-hook contents are not reconstructed. Dormant custom modules remain dormant. The upstream terminal-sender, Mojo syntax and aggregate vim-colorschemes snapshots lacked clear redistribution grants: native terminal transport preserves the exercised send protocol, and Mojo detection/LSP remain available, but that third-party Mojo syntax package, unlicensed aggregate palette collection and external IPython-kernel transport are not distributed. The selected Base16 theme is supplied from its licensed upstream instead. Parser binaries are platform-specific host prerequisites, not portable bundled binaries. macOS UI, clipboard hardware, live accounts, render/display devices and external toolchains require checks on the intended host.

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

From a clean recursive clone with Python 3 available:

```sh
make bundle
```

Python 3 is a maintainer-only bundle-build requirement. Installing and running a downloaded bundle remains Bash/POSIX-only and does not invoke Python.

This creates `dist/portable-dev-setup-1.0.1.tar.gz` and an outer SHA-256 file. The archive also contains `BUNDLE-SHA256SUMS`, covering every included file. It materializes all required shell and Neovim snapshots, their licenses, and the complete runtime payload. Archive ordering, timestamps, ownership, modes, and gzip metadata are canonicalized from the exact source commit so repeated builds produce identical files.

After downloading both files, verify and install without network access:

```sh
shasum -a 256 -c portable-dev-setup-1.0.1.tar.gz.sha256
tar -xzf portable-dev-setup-1.0.1.tar.gz
cd portable-dev-setup-1.0.1
./scripts/verify-checksums.sh BUNDLE-SHA256SUMS .
make install
```

On Linux, `sha256sum -c` can be used for the outer checksum.

## Proofs

```sh
make test          # structure, pins, profiles, backups, and shared payload
make prove         # isolated install plus bounded real zsh/Neovim assertions
make prove-bundle  # two-build byte proof, checksums, extraction, reinstall, and startup
```

The Linux/macOS proof jobs cover effective core/filetype settings, restored mappings, plugin surfaces, real terminal/buffer/snippet callbacks, missing-server safety, configured-only diagnostics, and instrumented formatting/account/process boundaries. Oil/Telescope defaults are exercised without adding redundant bindings. The extracted **actual bundle** runs the same regressions, including theme checks, after two byte-identical builds and checksum/metadata verification.

For the additional real Python/Org parser, calendar-file and marked-block fixtures, provide a runtime directory containing compatible `parser/python.so` and `parser/org.so`, plus host ripgrep:

```sh
PORTABLE_TEST_PARSERS=/path/to/parser-runtime make prove
```

Without those prerequisites the extra parser proof is explicitly reported as not run; account/render/player calls remain instrumented, not live-account evidence.

## Licensing

First-party files are MIT licensed. Third-party source remains under its original terms; exact commits and license custody are listed in [THIRD_PARTY_LICENSES.md](THIRD_PARTY_LICENSES.md).
