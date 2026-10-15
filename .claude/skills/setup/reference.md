# Setup reference

Keep this file accurate: update it whenever a component, file, convention, or gotcha changes.

## Contents
- [Map](#map)
- [Hyprland](#hyprland)
- [Waybar](#waybar)
- [Ghostty (terminal)](#ghostty-terminal)
- [Neovim](#neovim)
- [Launcher, notifications, lock/idle](#launcher-notifications-lockidle)
- [Helper scripts](#helper-scripts-localbin)
- [Dotfiles repo](#dotfiles-repo)
- [System](#system)

## Map

| What | Where |
|---|---|
| Compositor | `~/.config/hypr/hyprland.lua` (Hyprland 0.56, **Lua config**) |
| Idle / lock | `~/.config/hypr/hypridle.conf`, `hyprlock.conf` (hyprlang syntax) |
| Bar | `~/.config/waybar/config.jsonc`, `style.css`, `scripts/cava.sh` |
| Terminal | Ghostty: `~/.config/ghostty/config`, `shaders/*.glsl` |
| Old terminals | foot (`~/.config/foot/foot.ini`, still used by `keys`/`wallpick` popups), alacritty (no config, unused) |
| Editor | Neovim 0.12 + LazyVim: `~/.config/nvim/` (custom plugins in `lua/plugins/`) |
| Launcher | fuzzel: `~/.config/fuzzel/fuzzel.ini` |
| Notifications | mako: `~/.config/mako/config` |
| Wallpaper | `~/.config/wallpaper` (symlink to the chosen image, set by `setbg`) |
| Session target | `~/.config/systemd/user/hyprland-session.target` |
| Scripts | `~/.local/bin/` |
| Dotfiles | bare repo `~/.dotfiles`, alias in `~/.bashrc.d/dotfiles` |
| This skill | `~/.claude/skills/setup/` (tracked in dotfiles too) |

## Hyprland

`hyprland.lua` sections, in order:
1. `hl.monitor`, app variables (`terminal`, `fileManager`, `browser`, `menu`, `mod`).
2. **Autostart** in `hl.on("hyprland.start", …)`: systemd env export + `hyprland-session.target`,
   waybar, mako, polkit agent, nm-applet, blueman-applet, cliphist watcher, swaybg,
   hypridle, wlsunset (Paris coords), 1Password. VPN autoconnect is commented out.
3. `hl.env`: cursor size, qt6ct, Steam scaling.
4. `hl.config{}`: `general` (layout = `scrolling`, gaps 4/8, border 2), `xwayland.force_zero_scaling`,
   `decoration` (rounding 0, inactive_opacity 0.88, shadow, blur on), `scrolling` (column widths),
   `misc`, `input` (us altgr-intl, natural scroll, tap-to-click).
5. Animations: global off; only fades, window move, open/close popin, border are on
   (workspace switches instant on purpose).
6. Gestures: 3-finger horizontal = scroll columns, vertical = workspace.
7. Keybinds via local `bind(keys, dsp, opts)` = `SUPER + keys`. Raw `hl.bind` for unmodified keys.
8. Window rules (`hl.window_rule{ name, match = { class = … }, … }`): wallpick and keys float
   centered; Celeste gets `immediate` (tearing).

Key binds (mirror in `~/.local/bin/keys` when changing!): SUPER+Return terminal, Space
fuzzel, W close, F fullscreen, T float, L lock, Esc powermenu, Shift+Esc exit, Ctrl+V
clipboard history, E emoji picker, Shift+W wallpick, / cheatsheet, C/V/X universal copy/paste/cut,
arrows focus, Shift+arrows move, R/Shift+R/M/-/= column width, [ ] , . consume/expel,
1-9 workspaces (+Shift move), Tab/Shift+Tab next/prev, Print = region screenshot → swappy.

Gotchas:
- A `hyprland.lua.bak-*` file from an earlier change exists; `maintain backups` archives these.
- `misc.disable_hyprland_guiutils_check` is needed on Fedora (guiutils not packaged).

## Waybar

`config.jsonc`: left = `hyprland/workspaces` (`persistent-workspaces: {"*": 5}` keeps 1–5
always visible), center = clock + `custom/cava` (audio visualizer script), right =
1password, vpn (`~/.local/bin/vpn`, json class on/off), bluetooth, pulseaudio, network,
battery. `style.css` is the monochrome theme; transparent bar background.
Reload: `pkill -SIGUSR2 waybar`.

## Ghostty (terminal)

Installed from COPR `scottames/ghostty` (not in Fedora repos). Version 1.3.
`config`: JetBrainsMono Nerd Font 11, theme Catppuccin Mocha, `background-opacity = 0.9`
(Hyprland blurs behind it), no decorations, block cursor.

**Animated cursor** — `custom-shader = shaders/cursor_neovide.glsl` (written for this setup):
- Ghostty's own cursor is hidden (`cursor-opacity = 0`) and the shader draws the whole
  cursor; `cursor-text = cell-foreground` keeps the glyph under it visible, and the shader
  re-inks it in the background color. `cursor-style-blink = false` — the shader blinks.
- **1:1 port of Neovide's cursor** (neovide/neovide `src/renderer/cursor_renderer/mod.rs`
  `Corner::jump` + `calculate_direction_alignment`, `animation_utils.rs`
  `CriticallyDampedSpringAnimation`). Per-corner alignment with travel direction, min-max
  normalised to 0..1; length = `mix(ANIMATION_LENGTH, ANIMATION_LENGTH*(1-TRAIL_SIZE), a)`;
  jumps of <= 2 cells on one line use `SHORT_ANIMATION_LENGTH` for all corners; critically
  damped spring (omega = 4/length, no overshoot); lengths <= `FRAME_DT` snap (60 Hz panel).
  Pure Neovide only leans on diagonal moves. Added on top: `TILT` (-10) biases each corner's
  alignment along the move's perpendicular (bottom edge leads, top drags), and short jumps keep
  that per-corner spread scaled to `SHORT_ANIMATION_LENGTH` so typing leans too. `TILT = 0` = pure Neovide.
- Tunables (same names/defaults as `vim.g.neovide_cursor_*`): `ANIMATION_LENGTH` 0.150,
  `SHORT_ANIMATION_LENGTH` 0.04, `TRAIL_SIZE` 1.0, plus `TILT`, `FRAME_DT`, `BLINK_DELAY` (<0 disables;
  Neovide itself doesn't blink by default), `BLINK_PERIOD`.
- Known difference: a shader only sees previous/current cursor rects, so a move interrupting
  an animation restarts from the previous cell (Neovide continues from the live position).
- The earlier hand-tuned underdamped-spring version (TILT, MAX_LAG, DAMPING…) is in dotfiles
  commit 25a616b: `dot checkout 25a616b -- .config/ghostty/shaders/cursor_neovide.glsl`.
- Only `cursor_neovide.glsl` remains in `shaders/`. Removed alternatives (elastic,
  smear, smear_fade, blaze) are in dotfiles history (commit "ghostty: remove unused
  cursor shaders"); restore with `dot checkout <commit>^ -- .config/ghostty/shaders/<file>`.
  The smear/blaze ones assume a *visible* native cursor — drop `cursor-opacity = 0` if used.

Shader gotchas:
- Uniforms available (1.3): `iCurrentCursor`/`iPreviousCursor` (x=left, y=top, z=w, w=h,
  pixels, y up), `iCurrentCursorColor` (alpha = cursor-opacity, so use `.rgb`),
  `iTimeCursorChange`, `iFocus`, `iTimeFocus`, `iTime`, `iChannel0`, `iResolution`.
- Ghostty only animates frames while focused → shaders must not animate when `iFocus == 0`
  (otherwise a mid-animation frame freezes on screen).
- `half` is a reserved word in GLSL here; compile check via the `shadertoy` log line.
- Preserve alpha (`fragColor.a`) for background-opacity; force alpha 1 where drawing the cursor.

## Neovim

LazyVim starter (`init.lua`, `lua/config/*.lua`, `lua/plugins/*.lua`, `lazy-lock.json`).
Custom: `lua/plugins/animations.lua` — `smear-cursor.nvim` (disabled when
`TERM=xterm-ghostty` since Ghostty's shader animates the cursor) and snacks.nvim smooth
scroll. `lua/plugins/example.lua` is the inert LazyVim example. No LazyVim extras enabled.
Rollback plugin versions: `:Lazy restore` (uses lazy-lock.json).

## Launcher, notifications, lock/idle

- fuzzel: monochrome, JetBrainsMono 15; `terminal=ghostty -e` runs terminal apps.
  Also used as dmenu by clipboard bind and `powermenu`.
- mako: monochrome, 5s timeout.
- hypridle: on battery only — lock at 5 min, DPMS off at 5.5 min; locks before sleep.
- hyprlock: fingerprint + password, wallpaper blurred background, clock label.

## Helper scripts (`~/.local/bin`)

| Script | Purpose |
|---|---|
| `sysupdate` | dnf + flatpak + fwupd, Hyprland version diff + config check, snapper snapshots, reboot hint |
| `maintain` | interactive upkeep: check / backups / dotfiles / update / clean (`TRACK=()` = files backed up) |
| `keys` | SUPER+/ cheatsheet (Python TUI in a floating foot window). **Bind list is hardcoded.** |
| `powermenu` | fuzzel menu: lock/suspend/logout/reboot/shutdown |
| `emoji` | fuzzel emoji picker (SUPER+E): copies + types via `wtype` if installed. Data: `~/.local/share/emoji/emoji.txt`, generated from unicode.org `emoji-test.txt` (fully-qualified lines → `<emoji> <name>`) |
| `wallpick` | wallpaper picker (fzf + chafa in foot; local ~/Pictures + dharmx/walls) → `setbg` |
| `setbg <img>` | symlink image to `~/.config/wallpaper` and restart swaybg |
| `vpn [off\|status]` | openfortivpn (Okta) for Paris office; waybar module shows state |
| `webapp-install` / `webapp-remove` | Chromium app-window .desktop launchers (gum prompts) |

Scripts start with a `#` usage header comment — keep that convention for new scripts.

## Dotfiles repo

- `git --git-dir=$HOME/.dotfiles --work-tree=$HOME …` (alias `dot`), no remote.
- `status.showUntrackedFiles = no`: new files never show in `status` — they must be added
  explicitly (`add <path>`) or via `maintain dotfiles` after adding them to `TRACK`.
- Commit style: `<component>: <change>` or `Maintenance snapshot YYYY-MM-DD` (from maintain).
- What's tracked is defined by `TRACK` in `maintain` — add new config paths there.

## System

- Fedora 44, btrfs + snapper (root config), dnf5, flatpak, fwupd.
- Session env exported to systemd for xdg-desktop-portal via `hyprland-session.target`.
- Wireplumber drop-in: `~/.config/systemd/user/wireplumber.service.d/libcamera-tuning.conf`.
- Display scale 1.5. Laptop (battery, fingerprint reader, brightness keys).
- Apps built from source live in `~/src/`. **Omawrite** (Omarchy's Qt Markdown writer,
  github.com/omacom/omawrite) is Arch-only upstream, so it's built with `bin/build` (qmake6; needs
  `qt6-qtbase-devel qt6-qtdeclarative-devel gcc-c++ make`) and installed per-user:
  `~/.local/bin/omawrite`, `~/.local/share/applications/omawrite.desktop`,
  `~/.local/share/icons/hicolor/scalable/apps/omawrite.svg`. Update: `git -C ~/src/omawrite pull`,
  `bin/build`, re-copy `build/omawrite` to `~/.local/bin`. sysupdate does not update it.
