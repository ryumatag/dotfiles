<div align="center">

<samp>dotfiles</samp>
=====================
**My configuration files and personal collection of scripts.**

Licensed under the [UNLICENSE](https://unlicense.org).

</div>

## Design

This repo is built to hold every machine’s configuration—personal and work,
macOS and Linux—without splitting into multiple copies. Platform‑specific
files live under `darwin/` so non‑macOS hosts naturally skip them.

Private work hosts can layer their own dotfiles tree via `WORK_DOTFILES_ROOT`,
using the exact same directory shape, so “personal base + work overlay” stays
easy to reason about.

Symlinks are created by a small tool (`dotlink`) to make link targets
deterministic, reversible, and safe to re‑run.

Design rules:
* Shared defaults stay at the repo root; macOS‑only lives in `darwin/`.
* Overlays follow the same layout and override by path, highest‑priority win.
* Bootstrap must be idempotent: re‑running `dotsetup`/`dotlink` should be safe.

## Usage

### dotlink (symlink manager)

`bin/dotlink` materializes symlinks from this repo (and optional work overlay)
into your home:

* `link` - create/update symlinks (backs up existing real files under
  `.backup/<ts>/`).
* `unlink` - remove current symlinks created by dotlink.
* `status` - report OK/MISS/DIFF/FILE for expected links.
* `prune` - remove broken symlinks that pointed into dotfiles/work-dotfiles.

Priority when choosing a source (first match wins):

1. `WORK_DOTFILES_ROOT/darwin/...` (macOS && `bin/is-work` true)
2. `WORK_DOTFILES_ROOT/...`
3. `DOTFILES_ROOT/darwin/...` (macOS)
4. `DOTFILES_ROOT/...`

`link` wires:

* `$XDG_CONFIG_HOME/<name>` ← `.config/<name>` (or `darwin/.config/<name>` on
  macOS)
* `$HOME/.zshenv` ← `.config/zsh/.zshenv`
* `$LOCAL_BIN/<name>` ← `bin/<name>` (plus `darwin/bin/<name>` on macOS)

### dotsetup (bootstrap)

`bin/dotsetup` clones/updates the repo, runs `dotlink link`, and optionally
installs Rust toolchains and listed Cargo binaries. Environment flags:

* `DOTSETUP_SKIP_RUST=1`
* `DOTSETUP_SKIP_CARGO=1`

Note: dotsetup is still evolving; missing pieces will be filled as the setup
surface grows.

## Caveats

* This repo’s history may be rewritten and force‑pushed; rebase locally before
  pushing.
* macOS‑only pieces live under `darwin/`; Linux hosts will ignore them.
* Work overlay (`WORK_DOTFILES_ROOT`) is optional but, when present, overrides
  personal files per the priority above.
