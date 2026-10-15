# My machine

Fedora 44 laptop running **Hyprland** with scrolling columns (like niri) and
Omarchy-style shortcuts. Light monochrome theme for the bar, launcher, popups and
notifications; the terminal (Ghostty) is dark Catppuccin.

## Everyday use

| Shortcut | Does |
|---|---|
| **Super + /** | All shortcuts (searchable; always up to date) |
| Super + Space | Launch an app |
| Super + Return | Terminal |
| Super + W | Close window |
| Super + Ctrl + V | Clipboard history |
| Super + E | Emoji picker |
| Super + D | These docs |
| Super + Shift + W | Wallpaper picker |
| Super + L / Super + Escape | Lock / power menu |
| Print | Screenshot a region (then edit in swappy) |

Windows sit side by side in columns that scroll: Super + arrows moves focus,
Super + R cycles column widths, 3-finger swipe left/right scrolls, up/down
switches workspace.

**Bar (top):** workspaces · clock and audio visualizer · 1Password · VPN (click to
connect, right-click to disconnect) · Bluetooth · volume · Wi-Fi · battery.

## Keeping it healthy

- **Weekly: `sysupdate`.** Updates packages, Flatpaks and firmware, takes
  before/after snapshots, checks that the Hyprland config still works with the new
  version, and tells you if a reboot is needed.
- **Now and then: `maintain`.** Walks through: check configs, clean stray backup
  files, save config changes to the dotfiles repo, update, free disk space. It asks
  before each step. Run one step with e.g. `maintain check`.

## When something breaks

| Problem | Fix |
|---|---|
| Hyprland shows a config error | `maintain check` names the file and line |
| An update broke something | `sudo snapper list`, then `sudo snapper undochange <pre>..<post>` for that update |
| A config change went wrong | `dot log --oneline -- <file>`, then `dot checkout <commit> -- <file>` |
| Neovim plugins misbehave after an update | `:Lazy restore` in Neovim (back to the locked versions) |
| Something else | Ask Claude: it knows this setup (`~/.claude/skills/setup`) |

`dot` is git for the dotfiles repo (`~/.dotfiles`, files live in place in `~`).
Every config change is committed there, so any earlier version can come back.

## Changing things

Easiest: ask Claude. It edits the right file, validates it, reloads it and commits.
By hand: edit the file, run `maintain check`, then `maintain dotfiles` to save it.

| To change | Edit |
|---|---|
| Shortcuts, window rules, look, autostart | `~/.config/hypr/hyprland.lua` |
| Bar | `~/.config/waybar/` |
| Terminal / its cursor animation | `~/.config/ghostty/config` / `~/.config/ghostty/shaders/cursor_neovide.glsl` |
| Editor | `~/.config/nvim/` (LazyVim) |
| Lock / idle timings | `~/.config/hypr/hypridle.conf`, `hyprlock.conf` |
| Helper commands | `~/.local/bin/` |

Technical details (every component, file and gotcha): **Setup reference** in Super + D.
