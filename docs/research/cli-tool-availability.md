# CLI tool availability: Arch, Debian stable, Ubuntu LTS

Researched 2026-11-26. Question: for each optional tool the bash config may hook
(fzf, zoxide, bat, fd, eza, starship), is it in the official repos of Arch,
Debian stable (13 "trixie") and Ubuntu LTS (24.04 "noble"; 26.04 "resolute"
is released, Release file dated 2026-04-23), at which version, under which
binary name, and does that version support the bash integration we would use?

## How confident each column is

| Source | Method | Confidence |
|---|---|---|
| **Ubuntu 24.04 / 26.04** | Downloaded the archive's own `Packages.xz` indexes (`noble`, `noble-updates`, `noble-backports`, `resolute`, `resolute-updates`; `main` + `universe`) from `archive.ubuntu.com`, then downloaded each `.deb` and listed its files with `dpkg -c`. | **High**: read straight from the archive. |
| **Upstream** | Read the CHANGELOGs and source on GitHub (`raw.githubusercontent.com`). | **High** |
| **Debian 13** | `packages.debian.org`, `tracker.debian.org`, `sources.debian.org` and every Debian mirror tried were **blocked by this session's network policy**. Versions come from search-engine snippets of those primary pages, cross-checked against each other. | **Medium**: verify with `apt policy <pkg>` on a trixie box. |
| **Arch** | `archlinux.org` and all Arch mirrors were blocked the same way. Versions come from search snippets of `archlinux.org/packages/...` and `security.archlinux.org`. | **Medium**: these are snapshots. Arch is rolling, so the exact number matters less than the fact that it tracks upstream closely. |

I could not run the downloaded binaries (the session's permission policy
denied it), so "integration supported" rests on upstream changelogs and
source, not on running `fzf --bash` and similar against each distro build.

## Per-tool findings

### fzf: `eval "$(fzf --bash)"` needs >= 0.48.0

- Upstream: 0.48.0 is the release where "Shell integration scripts are now
  embedded in the fzf binary", with `eval "$(fzf --bash)"` as the bash
  setup ([fzf CHANGELOG, 0.48.0][fzf-cl]). The scripts are compiled in with
  `//go:embed shell/key-bindings.bash` / `shell/completion.bash`
  ([main.go @ 0.48.0][fzf-main]), so any distro build from source includes
  them. Latest upstream: 0.75.1.
- **Ubuntu 24.04**: `fzf 0.44.1-1` (release), and `0.44.1-1ubuntu0.3` in
  `noble-updates`/`-security`. Its changelog shows the updates are only
  Go-toolchain rebuilds with no upstream bump, so there is **no `--bash`**.
  Fallback files shipped in the .deb:
  - `/usr/share/doc/fzf/examples/key-bindings.bash` (must be sourced manually)
  - `/usr/share/bash-completion/completions/fzf` (auto-loaded by bash-completion)
  - Nothing newer in `noble-backports`.
- **Ubuntu 26.04**: `fzf 0.67.0-1`, so `--bash` works. The .deb also puts
  `key-bindings.bash` and `completion.bash` under
  `/usr/share/doc/fzf/examples/`.
- **Debian 13**: `fzf 0.60.3-1` (amd64 binNMU `0.60.3-1+b2`), so `--bash`
  works ([tracker][deb-fzf-tracker], [security tracker][deb-fzf-sec]).
- **Arch**: `extra/fzf 0.74.x` (snippet showed 0.74.4-1), so `--bash` works
  ([archlinux.org][arch-fzf]).
- Binary name is `fzf` everywhere.

**Consequence:** feature-detect rather than version-detect, e.g.
`fzf --bash >/dev/null 2>&1 && eval "$(fzf --bash)"`, falling back to
sourcing `/usr/share/doc/fzf/examples/key-bindings.bash` (Debian/Ubuntu) or
`/usr/share/fzf/key-bindings.bash` (Arch's traditional path). Only Ubuntu
24.04 needs the fallback.

### zoxide: `eval "$(zoxide init bash)"`

- Upstream: the `init` subcommand has existed since 0.2.0 (2020-03-11)
  ([zoxide CHANGELOG][zox-cl]). Bash `init` is supported by every packaged
  version. Latest upstream: 0.10.0 (2026-07-04).
- **Ubuntu 24.04**: `zoxide 0.9.3-1`. **Ubuntu 26.04**: `zoxide 0.9.8-1`.
- **Debian 13**: `rust-zoxide`/`zoxide 0.9.7-1` ([sources.debian.org][deb-zox-src], [tracker][deb-zox-tracker]).
- **Arch**: `extra/zoxide 0.10.0-1` ([archlinux.org][arch-zox]).
- Binary name is `zoxide` everywhere. The Ubuntu .debs ship no bash
  completion file (`init` provides it).

### bat (no shell init; used as `cat`/`MANPAGER`/fzf preview)

- **Ubuntu 24.04**: `bat 0.24.0-1build1`. **Ubuntu 26.04**: `bat 0.25.0-5ubuntu1`.
  In both, the binary is **`/usr/bin/batcat`** and the completion file is
  `completions/batcat`.
- **Debian 13**: `bat 0.25.0-2` ([sources.debian.org][deb-bat]). The binary is
  `batcat`; the Ubuntu packages are synced from Debian's `rust-bat` packaging.
- **Arch**: `extra/bat 0.26.1-3`, binary `bat` ([archlinux.org][arch-bat]).
- "Integration" here is aliasing/env vars, so any version works. Resolve the
  name with `command -v bat || command -v batcat`.

### fd (no shell init; used as `FZF_DEFAULT_COMMAND`)

- Package name is **`fd-find`** on Debian/Ubuntu and `fd` on Arch.
- **Ubuntu 24.04**: `fd-find 9.0.0-1`. **Ubuntu 26.04**: `fd-find 10.3.0-2ubuntu1`.
  The binary is **`/usr/bin/fdfind`**. Note that the bash completion file is
  `completions/fd.bash`, which is keyed to `fd`, not `fdfind`.
- **Debian 13**: `fd-find 10.2.0-1` (amd64 `10.2.0-1+b5`), binary `fdfind`
  ([packages.debian.org trixie][deb-fd], [tracker][deb-fd-tracker]).
- **Arch**: `extra/fd 10.5.0-3`, binary `fd` ([archlinux.org][arch-fd]).
- Resolve with `command -v fd || command -v fdfind`.

### eza (no shell init; used as `ls` alias)

- **Ubuntu 24.04**: `eza 0.18.2-1`. **Ubuntu 26.04**: `eza 0.23.4-1ubuntu1`.
  The binary is `eza`, and the package also installs a `/usr/bin/exa -> eza`
  symlink.
- **Debian 13**: `eza 0.21.0-1` ([sources.debian.org][deb-eza], [Repology][repology-eza]).
  An older cached search page said 0.20.9-1. The tracker's stable field says 0.21.0-1.
- **Arch**: in `extra` as `eza`. I could not get an x86_64 version page; Arch
  Linux ARM shows 0.23.5-2, and x86_64 is expected to match or be newer.
- Binary name is `eza` everywhere. Aliases work with any version. Flags such
  as `--icons=auto` arrived in 0.18 or earlier, so all packaged versions should
  have them. I did not verify this per flag; check the flags the aliases use
  against 0.18.2.

### starship: `eval "$(starship init bash)"`

- **Ubuntu 24.04: not packaged.** It is absent from noble `main`/`universe`,
  `-updates` and `-backports`.
- **Ubuntu 26.04**: `starship 1.22.1-9ubuntu1`. `starship init bash` is the
  long-standing upstream bash setup, so this version supports it.
- **Debian 13**: `starship 1.22.1-6` per the trixie (stable) listing on a
  packages.debian.org mirror ([trixie/starship][deb-starship]). Debian
  packaged starship during the trixie cycle (testing logs show 1.22.1-4/-5
  ([piuparts][deb-starship-piu])). **This is the least certain Debian cell:**
  confirm with `apt policy starship` on trixie.
- **Arch**: `extra/starship 1.26.0-1` per the Arch security tracker
  ([security.archlinux.org][arch-starship]). Latest upstream is 1.27.0
  (2026-10-17).
- Binary name is `starship` everywhere.

## Decision table

| tool | Arch (extra) | Debian 13 trixie | Ubuntu 24.04 noble | Ubuntu 26.04 resolute | binary name | integration supported? |
|---|---|---|---|---|---|---|
| fzf | 0.74.x | 0.60.3 | 0.44.1 | 0.67.0 | `fzf` | `fzf --bash` (>= 0.48): Arch yes, Debian yes, 26.04 yes, **24.04 no**. On 24.04, source `/usr/share/doc/fzf/examples/key-bindings.bash` |
| zoxide | 0.10.0 | 0.9.7 | 0.9.3 | 0.9.8 | `zoxide` | `zoxide init bash`: **yes everywhere** (since 0.2.0) |
| bat | 0.26.1 | 0.25.0 | 0.24.0 | 0.25.0 | Arch `bat`; Debian/Ubuntu **`batcat`** | N/A (alias/env only), yes everywhere |
| fd | `fd` 10.5.0 | `fd-find` 10.2.0 | `fd-find` 9.0.0 | `fd-find` 10.3.0 | Arch `fd`; Debian/Ubuntu **`fdfind`** | N/A (used by fzf), yes everywhere |
| eza | yes (version unconfirmed, ~0.23) | 0.21.0 | 0.18.2 | 0.23.4 | `eza` (Debian/Ubuntu also `exa` symlink) | N/A (alias only), yes everywhere |
| starship | 1.26.0 | 1.22.1 (verify) | **not packaged** | 1.22.1 | `starship` | `starship init bash`: yes wherever installed; **24.04 has no package** |

Bash-side implications:

1. Hook every tool behind `command -v`. Check for `batcat` and `fdfind` as
   alternate names on Debian/Ubuntu.
2. For fzf, feature-test `fzf --bash` and fall back to the examples script. Only
   Ubuntu 24.04 hits the fallback.
3. starship cannot be installed from repos on Ubuntu 24.04. With the
   `command -v` guard the prompt simply stays default there.

## Sources

- Ubuntu archive (primary, read directly):
  `http://archive.ubuntu.com/ubuntu/dists/{noble,noble-updates,noble-backports,resolute,resolute-updates}/{main,universe}/binary-amd64/Packages.xz`,
  plus the `.deb` files under `http://archive.ubuntu.com/ubuntu/pool/universe/`
  (`f/fzf/`, `r/rust-bat/`, `r/rust-fd-find/`, `r/rust-eza/`, `r/rust-zoxide/`, `s/starship/`).
  The fzf 24.04 changelog was read from `/usr/share/doc/fzf/changelog.Debian.gz`
  inside `fzf_0.44.1-1ubuntu0.3_amd64.deb`.
- fzf-cl: <https://github.com/junegunn/fzf/blob/master/CHANGELOG.md>
- fzf-main: <https://github.com/junegunn/fzf/blob/0.48.0/main.go>
- zox-cl: <https://github.com/ajeetdsouza/zoxide/blob/main/CHANGELOG.md>
- starship changelog: <https://github.com/starship/starship/blob/master/CHANGELOG.md>
- deb-fzf-tracker: <https://tracker.debian.org/pkg/fzf>
- deb-fzf-sec: <https://security-tracker.debian.org/tracker/source-package/fzf>
- deb-zox-src: <https://sources.debian.org/src/rust-zoxide/>
- deb-zox-tracker: <https://tracker.debian.org/pkg/rust-zoxide>
- deb-bat: <https://sources.debian.org/patches/rust-bat/>
- deb-fd: <https://packages.debian.org/trixie/amd64/fd-find>
- deb-fd-tracker: <https://tracker.debian.org/pkg/rust-fd-find>
- deb-eza: <https://sources.debian.org/src/rust-eza/>
- repology-eza: <https://repology.org/project/eza/versions>
- deb-starship: <https://packages-pkgmirror-csail.debian.org/trixie/starship>
- deb-starship-piu: <https://piuparts.debian.org/testing2sid/pass/starship_1.22.1-5.log>
- arch-fzf: <https://archlinux.org/packages/extra/x86_64/fzf/>
- arch-zox: <https://archlinux.org/packages/extra/x86_64/zoxide/>
- arch-bat: <https://archlinux.org/packages/extra/x86_64/bat/>
- arch-fd: <https://archlinux.org/packages/extra/x86_64/fd/>
- arch-starship: <https://security.archlinux.org/package/starship>

[fzf-cl]: https://github.com/junegunn/fzf/blob/master/CHANGELOG.md
[fzf-main]: https://github.com/junegunn/fzf/blob/0.48.0/main.go
[zox-cl]: https://github.com/ajeetdsouza/zoxide/blob/main/CHANGELOG.md
[deb-fzf-tracker]: https://tracker.debian.org/pkg/fzf
[deb-fzf-sec]: https://security-tracker.debian.org/tracker/source-package/fzf
[deb-zox-src]: https://sources.debian.org/src/rust-zoxide/
[deb-zox-tracker]: https://tracker.debian.org/pkg/rust-zoxide
[deb-bat]: https://sources.debian.org/patches/rust-bat/
[deb-fd]: https://packages.debian.org/trixie/amd64/fd-find
[deb-fd-tracker]: https://tracker.debian.org/pkg/rust-fd-find
[deb-eza]: https://sources.debian.org/src/rust-eza/
[repology-eza]: https://repology.org/project/eza/versions
[deb-starship]: https://packages-pkgmirror-csail.debian.org/trixie/starship
[deb-starship-piu]: https://piuparts.debian.org/testing2sid/pass/starship_1.22.1-5.log
[arch-fzf]: https://archlinux.org/packages/extra/x86_64/fzf/
[arch-zox]: https://archlinux.org/packages/extra/x86_64/zoxide/
[arch-bat]: https://archlinux.org/packages/extra/x86_64/bat/
[arch-fd]: https://archlinux.org/packages/extra/x86_64/fd/
[arch-starship]: https://security.archlinux.org/package/starship
