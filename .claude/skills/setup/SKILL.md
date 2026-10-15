---
name: setup
description: Modify, fix, or maintain this machine's desktop setup — Hyprland (Lua config), Waybar, Ghostty, Neovim (LazyVim), fuzzel, mako, hypridle/hyprlock, wallpaper, the ~/.local/bin helper scripts, dotfiles repo, and system upkeep (sysupdate/maintain). Use for ANY change to config files under ~/.config or ~/.local/bin, keybinds, theming, autostart, animations, bar modules, terminal looks, editor plugins, or questions about how the setup works or how to maintain it.
---

# Desktop setup: how it works and how to change it

Fedora 44 + Hyprland (scrolling/niri-style layout, Omarchy-style binds), monochrome
light theme across bar/launcher/notifications. Everything user-facing lives in
`~/.config/*` and `~/.local/bin/*`, versioned in a **bare git repo** at `~/.dotfiles`
(work tree = `$HOME`, shell alias `dot`).

Component details, file map, and known gotchas: **[reference.md](reference.md)** — read
the relevant section before editing a component.

## Workflow for every change

1. **Look first.** Read the file you're changing (and the component's section in
   reference.md). Check `dot status --short` so you know what's already uncommitted.
2. **Back up only via git, not `.bak` files.** The dotfiles repo is the backup. If a
   file is untracked, add it in step 6. Don't leave `*.bak*`/`*.orig` copies
   around; `maintain backups` exists to clean those up.
3. **Edit in the existing style.** Match comments/naming of the file. Hyprland's config
   is **Lua** (`hl.config{}`, `hl.bind`, `hl.window_rule`…), not hyprlang `.conf` syntax.
4. **Validate**: `maintain check` validates everything at once (Hyprland, fuzzel, Ghostty,
   Waybar, mako, Lua syntax of nvim + docs viewer, live session errors). Extra per-component
   checks are in the table below. Never finish with an unvalidated config.
5. **Apply/reload** so the user sees it now (table below). Prefer reloads over restarts.
6. **Record it:**
   - Commit to dotfiles: `git --git-dir=$HOME/.dotfiles --work-tree=$HOME add <files> && … commit -m "<component>: <what>"`
     (the alias `dot` only exists in interactive shells). Only commit files you changed;
     leave the user's other uncommitted edits alone unless asked. Don't push (no remote).
   - New config file → `dot add` it. It must sit under a folder in `WATCH=(…)` in
     `~/.local/bin/maintain` (add the folder if not), so future snapshots keep it.
     Files to never back up go in `~/.dotfiles/info/exclude`.
   - Added/changed a keybind → give it a `desc` ("Section|What it does") in `hyprland.lua`;
     the SUPER+/ cheatsheet picks it up automatically.
   - Changed how a component works (new tool, new file, new convention, new gotcha) →
     update **reference.md** in this skill so the docs stay true.
   - Changed something the user sees or does (shortcut they'd use daily, upkeep, recovery) →
     update **README.md** (the user's own overview; plain language, no internals).
7. **Report** what changed, where, how to tweak it, and anything not verified visually.

## Validate & reload cheat sheet

| Component | Validate | Apply |
|---|---|---|
| Hyprland `~/.config/hypr/hyprland.lua` | `Hyprland --verify-config -c ~/.config/hypr/hyprland.lua` (expect `config ok`), then `hyprctl configerrors` | auto-reloads on save; force: `hyprctl reload` |
| hypridle / hyprlock | — | `pkill hypridle; hypridle & disown` / next lock |
| Waybar `~/.config/waybar/` | JSONC must parse; watch `waybar` stderr | `pkill -SIGUSR2 waybar` |
| Ghostty `~/.config/ghostty/config` | `ghostty +validate-config` | in-app `Ctrl+Shift+,` (some keys e.g. opacity need a new window) |
| Ghostty shaders (not in `maintain check`: opens a window) | `timeout 3 ghostty -e true 2>&1 \| grep -iE 'shadertoy\|spirv\|ERROR:'` → must say `loaded custom shader` | same reload |
| Neovim `~/.config/nvim/` | `maintain check` (Lua syntax); new plugins: `nvim --headless "+Lazy! install" +qa`. A plain headless start does **not** show LazyVim config errors | reopen nvim |
| fuzzel | `fuzzel --check-config` | next launch |
| mako | `makoctl reload` (errors shown) | same |
| Whole setup | `maintain check` (also after every change) | — |

## Constraints

- **sudo needs a password** (no passwordless sudo). For package installs, write the
  command and ask the user to run it with `! <cmd>` in the prompt; continue configuring
  meanwhile.
- **Don't open test windows casually.** New windows steal focus and swallow the user's
  keystrokes. If a visual check is needed, prefer offline simulation/screenshots of
  existing state, or launch with `--class=claude.test`, keep it brief, and say so.
  Screenshots: `grim -g "x,y WxH" file.png` with geometry from `hyprctl clients -j`.
- Don't run `Lazy! sync` (updates every plugin) unless asked; use `Lazy! install`.
- Keep the visual language consistent: monochrome `#efefef` / `#2c2c2c` / `#565656` /
  `#8a8a8a` / `#bababa`, JetBrainsMono Nerd Font, square corners (radius 0).
  (Exception: Ghostty uses dark Catppuccin Mocha by choice.)
- Big or risky changes (layout switch, removing components, system packages): confirm first.

## Maintenance (point the user here)

- `sysupdate` — dnf (snapper pre/post snapshots), flatpak, firmware, Hyprland version
  diff + config check against the new binary, reboot hint. Undo a dnf transaction:
  `sudo snapper undochange <pre>..<post>`.
- `maintain` — interactive: `check`, `backups` (archive stray .bak files to
  `~/.local/share/dotfiles-archive`), `dotfiles` (commit changes, offer new files in WATCH folders),
  `update` (runs sysupdate), `clean` (autoremove, caches, journal, trash).
  Run single steps: `maintain check dotfiles`.
- After a Hyprland update, the Lua API can change: run `maintain check`, read the
  release notes link sysupdate prints, fix `hyprland.lua`.
