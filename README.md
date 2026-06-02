[![en](https://img.shields.io/badge/lang-English-blue.svg)](README.md)
[![zh-CN](https://img.shields.io/badge/lang-中文-red.svg)](README.zh-CN.md)

# dotfiles

My personal macOS dotfiles, layered for cross-machine sharing while keeping machine-specific and private config off GitHub. Deployed with [GNU Stow](https://www.gnu.org/software/stow/) into `~/.config/`.

## Layout

**On GitHub** (what you see after `git clone`):

```text
dotfiles/
├── README.md
├── README.zh-CN.md
├── .gitignore
├── .markdownlint-cli2.yaml  ← repo-local README lint config
├── install.sh                ← optional brew bootstrap (formulas + casks)
└── shared/                    ← tracked, portable across machines
    ├── ghostty/config
    ├── git/{config, dotfiles, ignore, gitignore_global, identity-personal, hooks/}
    ├── karabiner/karabiner.json
    ├── starship/starship.toml
    ├── wezterm/wezterm.lua
    ├── yazi/{yazi.toml, keymap.toml, package.toml, plugins/}
    └── zsh/main.zsh
```

**After you populate `local/` on a machine** (gitignored, **never** uploaded):

```text
dotfiles/
├── ... (everything above) ...
└── local/                     ← gitignored, per-machine overrides
    ├── ghostty/local.conf     ← background-image, absolute paths
    ├── git/config.local       ← [user] name + email for this machine
    ├── wezterm/local.lua      ← returns a function that mutates wezterm config
    ├── yazi/local.lua         ← table: key → directory path (yazi bookmarks)
    └── zsh/local.zsh          ← machine-local PATH / aliases / proxy / conda init (any per-machine override)
```

> **Important**: `local/` is `.gitignore`d. A fresh `git clone` produces **no** `local/` directory — you create it by hand only on machines that need machine-specific overrides. Every `shared/` config is written to tolerate a missing `local/`, so the repo works as-is on a clean machine.

Both `shared/` and `local/` are independent stow packages. After stow, `~/.config/<tool>/...` becomes symlinks pointing into this repo.

## Why this layout

- **`shared/` = portable.** Cross-machine, publicly visible, no machine-specific or sensitive/identifying content.
- **`local/` = per-machine.** Lives only where it's needed: user identity, machine-specific paths, proxy/network settings, private bookmarks, secrets — anything that differs between machines or shouldn't be public (work-specific config being one such case).
- **Soft-load bridges.** Each `shared/` config loads its `local/` counterpart with a "file exists → source, missing → silent skip" pattern. A clean clone runs cleanly without any `local/` file.

## Quick start (new machine)

Requires macOS and Homebrew (see [brew.sh](https://brew.sh)). `stow` and other CLI deps can be installed via `install.sh` in step 2.
This repo is designed for the clone path `~/dotfiles`; the dotfiles-only Git hook and identity include intentionally target that path.

```bash
# 1. Clone
git clone git@github.com:Sniperqwer/dotfiles.git ~/dotfiles

# 2. (Optional) Install the brew packages this repo depends on.
#    See `bash install.sh -h` for flags. Skip if you manage brew packages yourself.
cd ~/dotfiles && bash install.sh        # CLI only
# bash install.sh --all                  # CLI + casks (Ghostty, WezTerm, Karabiner, Typora, font)

# 3. If ~/.config/<tool> already exists as a real directory, back it up first
#    and remove it so stow has a clean target:
#    cp -aR ~/.config ~/.config.bak.$(date +%F)
#    rm -rf ~/.config/{ghostty,git,karabiner,starship,wezterm,yazi,zsh}

# 4. Deploy shared (mandatory)
cd ~/dotfiles
stow -v --target="$HOME/.config" --no-folding shared

# 5. Deploy local (only if you've created one — on machines that need per-machine overrides)
[ -d local ] && stow -v --target="$HOME/.config" --no-folding local

# 6. Make sure ~/.zshrc sources the deployed main.zsh
#    (add the line below if it isn't there):
#    source "$HOME/.config/zsh/main.zsh"

# 7. (yazi only) install upstream plugins listed in package.toml
cd ~/.config/yazi && ya pkg install

# 8. Verify the pre-commit hook is wired up (README sync guard).
#    `shared/git/config` loads `shared/git/dotfiles` only for `~/dotfiles`;
#    that file sets `core.hooksPath = ~/.config/git/hooks`. The hook is committed
#    with mode 100755, so git preserves the +x bit on clone — no chmod needed in
#    normal cases.
git -C ~/dotfiles config core.hooksPath          # → ~/.config/git/hooks
ls -l ~/.config/git/hooks/pre-commit             # → symlink into shared/git/hooks/
[ -x ~/.config/git/hooks/pre-commit ] && echo "hook executable: yes"

#    If the last check prints nothing (e.g. you copied the file by hand, or git's
#    core.fileMode is off on this filesystem), restore the bit:
#    chmod +x ~/dotfiles/shared/git/hooks/pre-commit
```

`--no-folding` is required — it keeps `~/.config/<tool>/` as a real directory, so karabiner-elements and `ya pkg install` can write their own files there without contaminating this repo.

## What's tracked + load mechanism

| Tool      | shared entry                          | local override                 | Bridge                                                                    |
|-----------|---------------------------------------|--------------------------------|---------------------------------------------------------------------------|
| zsh       | `shared/zsh/main.zsh`                 | `local/zsh/local.zsh`          | `[ -f .../local.zsh ] && source` at the end of `main.zsh`                 |
| git       | `shared/git/config`                   | `local/git/config.local`       | `[include] path = ~/.config/git/config.local`                             |
| git (dotfiles) | `shared/git/dotfiles`, `shared/git/identity-personal` | — | `[includeIf "gitdir:~/dotfiles/"]` loads dotfiles-only hooks + public noreply identity |
| ghostty   | `shared/ghostty/config`               | `local/ghostty/local.conf`     | `config-file = ?local.conf` (the `?` prefix makes it optional)            |
| wezterm   | `shared/wezterm/wezterm.lua`          | `local/wezterm/local.lua`      | `pcall(dofile, "~/.config/wezterm/local.lua")` returns a mutator function |
| yazi      | `shared/yazi/{*.toml, plugins/}`      | `local/yazi/local.lua`         | shared keymap pre-registers `g+<letter>` slots that all dispatch to the `goto-bookmark` plugin; the plugin reads `local.lua` via `pcall(dofile, ...)` — local just edits `local.lua` |
| karabiner | `shared/karabiner/karabiner.json`     | —                              | (no include mechanism; keep all rules in shared)                          |
| starship  | `shared/starship/starship.toml`       | —                              | (theme only; no per-machine overrides)                                    |
| git-hooks | `shared/git/hooks/pre-commit`         | —                              | `core.hooksPath = ~/.config/git/hooks` in `shared/git/dotfiles`, loaded only for `~/dotfiles` |

## Common tasks

### Edit a tracked config

```bash
$EDITOR ~/dotfiles/shared/<tool>/<file>
# Symlinks are already in place — the change takes effect on the next program load.
```

### Add a machine-local override

```bash
mkdir -p ~/dotfiles/local/<tool>
$EDITOR ~/dotfiles/local/<tool>/<file>
cd ~/dotfiles && stow -v --restow --target="$HOME/.config" --no-folding local
```

Example: personal directory shortcuts such as `alias gs='cd ~/self/'` belong in `local/zsh/local.zsh`, not in `shared/zsh/main.zsh`.

### Add a new tool to shared

```bash
mkdir -p ~/dotfiles/shared/<tool>
cp ~/.config/<tool>/<file> ~/dotfiles/shared/<tool>/<file>
rm -rf ~/.config/<tool>          # back up first if you're unsure
cd ~/dotfiles && stow -v --restow --target="$HOME/.config" --no-folding shared
```

### Restow after structural changes (adding/removing files)

```bash
cd ~/dotfiles
stow -v -R --target="$HOME/.config" --no-folding shared
stow -v -R --target="$HOME/.config" --no-folding local
```

### Uninstall (revert to a plain `~/.config`)

```bash
cd ~/dotfiles
stow -D --target="$HOME/.config" --no-folding shared local
# Then restore from your ~/.config.bak.* backup or set the configs up manually.
```

## Conventions

- **Local file naming.** Files inside `local/` either end with `.local` (e.g. `config.local`) or start with `local.` (e.g. `local.conf`). `.gitignore` enforces `shared/**/*.local` and `shared/**/local.*` as a typo guard, so a misplaced local file can't sneak into git.
- **Yazi plugins.** Only the three self-written plugins under `shared/yazi/plugins/` are tracked. Anything `ya pkg install` installs (piper, rich-preview, toggle-pane, …) is blocked by `shared/yazi/plugins/*.yazi/` plus a `!`-allowlist for the three self-written ones.
- **Git identity.** Commits in `~/dotfiles` always carry the public GitHub noreply identity (`Sniper <169253722+Sniperqwer@users.noreply.github.com>`) thanks to the `includeIf "gitdir:~/dotfiles/"` rule, regardless of the machine's default identity.
- **`CLAUDE.md` is gitignored repo-wide.** If you want repo-level Claude Code instructions, add a section here instead.
- **Yazi bookmark slots.** `shared/yazi/keymap.toml` pre-registers `g+<letter>` for `s w p r i j m n b k t u v x y z q` — they all dispatch to the `goto-bookmark` plugin. To add a new jump on a machine, edit `local/yazi/local.lua` only (no shared change needed). The plugin shows a notification if a letter has no entry. Built-in yazi g-navigations are kept untouched: `g+g`, `g+h`, `g+c`, `g+d`, `g+f`, `g+<Space>`.
- **README stays in sync with `shared/` structure.** A pre-commit hook at `shared/git/hooks/pre-commit`, wired only for `~/dotfiles` via `shared/git/dotfiles`, blocks any commit that adds or removes a top-level `shared/<tool>/` directory unless both `README.md` and `README.zh-CN.md` are staged. Bypass intentionally with `git commit --no-verify`.
- **README lint is repo-local.** `.markdownlint-cli2.yaml` configures `markdownlint-cli2` for this repository's READMEs only; it is not a machine-wide Markdown policy.
- **Typora dependency.** The zsh `md` alias and yazi `open-typora` plugin expect Typora. It is installed by `bash install.sh --cask` or `bash install.sh --all`.
- **Guarded zsh integrations.** `shared/zsh/main.zsh` only initializes optional brew shell integrations when the relevant files or commands exist, so a partial bootstrap does not break shell startup.

## For LLM agents (Claude Code etc.)

**Where new content goes**:

- Cross-machine, nothing machine-specific or sensitive → `shared/<tool>/...`
- Specific to one machine (machine identity/email, local or internal paths, proxy/network settings, private bookmarks, API tokens — anything that differs per machine or shouldn't be public) → `local/<tool>/...`

**Hard rules**:

1. **Never** write private or machine-identifying strings into `shared/` — it's public. This covers anything that ties the config to a person, machine, or network: personal **or** employer email, company names, internal hostnames, kube context names, internal infra paths, absolute machine paths, tokens/secrets. When unsure, default to `local/`.
2. **Never** commit anything under `local/`. It's gitignored — don't bypass it.
3. **Never** add a `user.name` / `user.email` to `shared/git/config`. The machine's default identity belongs in `local/git/config.local`, or per-repo in a target repo's own `.git/config`.
4. **Don't** disable `--no-folding` when running stow. Karabiner-Elements and `ya pkg` depend on `~/.config/<tool>/` being a real directory.
5. **Don't** add files under `shared/yazi/plugins/<upstream>.yazi/`. Those are managed by `ya pkg` and `.gitignore` will block them anyway.
6. **When you add or remove a tool under `shared/<tool>/`, you MUST update BOTH `README.md` and `README.zh-CN.md`** in the same commit: the "Layout" tree, the "What's tracked + load mechanism" table, and any tool-specific hard rules. The pre-commit hook requires both files to be staged.
7. **When you introduce a hard rule that changes contributor behavior, add it to both READMEs.** The "Hard rules" lists are the source of truth for both humans and agents.

**Useful greps for context**:

```bash
git ls-files                            # everything tracked
rg -l '~/\.config/' shared/             # files that reference deployed paths
git config --show-origin user.email     # which file is providing identity
markdownlint-cli2 README.md README.zh-CN.md
readlink ~/.config/<tool>/<file>        # confirm the symlink target
```

**Adding a new soft-load bridge** (a `shared/` config that should pick up a `local/` override): prefer the tool's native include mechanism — zsh `source`, git `[include]`, ghostty `config-file = ?...`. For Lua-based tools use `pcall(dofile, ...)`. If the tool has no include mechanism (karabiner, starship), keep everything in `shared/` and don't invent one.

## Troubleshooting

- **`g w` in yazi shows "No bookmark key given".** The `goto-bookmark` plugin's entry signature must be `function entry(self, job)` — yazi 26.x passes `self` as the first argument. Verify the plugin file if this regresses after a yazi upgrade.
- **Karabiner-Elements wrote a real file over the symlink.** The GUI sometimes does an atomic rename, replacing the symlink. Move your changes back into `shared/karabiner/karabiner.json` and run `stow -R --no-folding shared`.
- **`git config user.email` returns the machine-default address inside `~/dotfiles` instead of the repo's noreply identity.** The `includeIf "gitdir:~/dotfiles/"` rule needs the trailing slash and the exact path, and `~/.config/git/dotfiles` must exist after restowing `shared/`. Verify with `git config --show-origin user.email` inside the repo.
- **Stow reports a conflict on first deploy.** A pre-existing real directory is at the target path. Back it up, `rm -rf` it, then re-stow.
- **`pre-commit` hook blocks a commit complaining about README sync.** You added or removed a top-level `shared/<tool>/` directory. Update both `README.md` and `README.zh-CN.md`, stage both files, and commit again; pass `--no-verify` only when bypassing intentionally.
- **`g+s` (or any `g+<letter>`) in yazi shows "No bookmark for: X".** Add `X = "..."` to `local/yazi/local.lua`. All reserved letters in shared keymap dispatch to the bookmark plugin; the actual paths live in `local/`.
