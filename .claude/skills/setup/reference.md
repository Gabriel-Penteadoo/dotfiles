# Setup reference

How the setup is built: every component, file and gotcha, as it is now. History lives in
git (`dot log`), not here. Keep this accurate whenever something changes; the user-facing
overview is `README.md` next to this file.

## Contents
- [Map](#map)
- [Hyprland](#hyprland)
- [Waybar](#waybar)
- [Ghostty (terminal)](#ghostty-terminal)
- [Neovim](#neovim)
- [Launcher, notifications, lock/idle](#launcher-notifications-lockidle)
- [Helper scripts](#helper-scripts-localbin)
- [Docs viewer](#docs-viewer)
- [Dotfiles repo](#dotfiles-repo)
- [System](#system)

## Map

| What | Where |
|---|---|
| Compositor | `~/.config/hypr/hyprland.lua` (Hyprland 0.56, **Lua config**) |
| Idle / lock | `~/.config/hypr/hypridle.conf`, `hyprlock.conf` (hyprlang syntax) |
| Bar | `~/.config/waybar/config.jsonc`, `style.css`, `scripts/cava.sh` |
| Terminal | Ghostty: `~/.config/ghostty/config`, `shaders/cursor_neovide.glsl` |
| Popup terminal | foot: `~/.config/foot/foot.ini` (for the `keys`, `wallpick`, `docs` popups) |
| Editor | Neovim 0.12 + LazyVim: `~/.config/nvim/` |
| Launcher | fuzzel: `~/.config/fuzzel/fuzzel.ini` |
| Notifications | mako: `~/.config/mako/config` |
| Docs viewer | `~/.config/docview/viewer.lua` |
| Wallpaper | `~/.config/wallpaper` (symlink, set by `setbg`) |
| Session target | `~/.config/systemd/user/hyprland-session.target` |
| Launchers | `~/.local/share/applications/` (web apps, vpn, omawrite) |
| Scripts | `~/.local/bin/` |
| Shell | bash; `~/.bashrc` sources `~/.bashrc.d/*` (`dotfiles`, `functions`, `prompt`, `tools`) |
| Dotfiles | bare repo `~/.dotfiles`, alias in `~/.bashrc.d/dotfiles` |
| Docs | `~/.claude/skills/setup/` (README.md, reference.md, SKILL.md) |

## Hyprland

`hyprland.lua` sections, in order:
1. `hl.monitor`, app variables (`terminal`, `fileManager`, `browser`, `menu`, `mod`).
2. **Autostart** in `hl.on("hyprland.start", …)`: systemd env export + `hyprland-session.target`,
   waybar, mako, polkit agent, nm-applet, blueman-applet, cliphist watcher, `setbg` (swaybg),
   hypridle, wlsunset (Paris coords), 1Password. VPN autoconnect is commented out.
3. `hl.env`: cursor size, qt6ct, Steam scaling.
4. `hl.config{}`: `general` (layout = `scrolling`, gaps 4/8, border 2), `xwayland.force_zero_scaling`,
   `decoration` (rounding 0, inactive_opacity 0.88, shadow, blur), `scrolling` (column widths),
   `misc`, `input` (us altgr-intl, natural scroll, tap-to-click).
5. Animations: global off; only fades, window move, open/close popin and border are on
   (workspace switches are instant on purpose).
6. Gestures: 3-finger horizontal = scroll columns, vertical = workspace.
7. Keybinds: `bind(keys, dsp, desc, opts)` = `SUPER + keys`; `key(…)` for unmodified keys.
   `desc` = `"Section|What it does[|key label]"` is the cheatsheet entry. Binds that share
   one cheatsheet line (arrows, C/X/V…) describe only the first.
8. Window rules (`hl.window_rule{ name, match = { class = … }, … }`): wallpick, keys and
   docview float centered; Celeste gets `immediate` (tearing); omawrite is slightly transparent.

Key binds: SUPER+/ (built from `hyprctl binds -j`, so always current).

Gotchas:
- `misc.disable_hyprland_guiutils_check` is needed on Fedora (guiutils not packaged).
- `--verify-config` accepts unknown option names, so a typo in a bind's opts passes the
  check silently. Confirm new options live (`hyprctl binds -j`, `hyprctl configerrors`).
- A Lua error stops the config at that line: everything after it (binds, rules) is
  missing from the live session until fixed. Always `hyprctl configerrors` after a reload.

## Waybar

`config.jsonc`: left = `hyprland/workspaces` (`persistent-workspaces: {"*": 5}` keeps 1–5
visible), center = clock + `custom/cava` (audio visualizer), right = 1password, vpn
(`~/.local/bin/vpn`, json class on/off), bluetooth, pulseaudio, network, battery.
`style.css` is the monochrome theme with a transparent bar. Reload: `pkill -SIGUSR2 waybar`.

## Ghostty (terminal)

From COPR `scottames/ghostty` (not in Fedora repos), version 1.3. `config`: JetBrainsMono
Nerd Font 11, Catppuccin Mocha, `background-opacity = 0.9` (Hyprland blurs behind it), no
decorations, touchpad scroll halved (`mouse-scroll-multiplier = precision:0.5,discrete:3`).

**Animated cursor** (`shaders/cursor_neovide.glsl`):
- Ghostty's cursor is hidden (`cursor-opacity = 0`); the shader draws it and re-inks the
  glyph under it (`cursor-text = cell-foreground`). It also blinks (`cursor-style-blink = false`).
- Port of Neovide's cursor (`src/renderer/cursor_renderer/mod.rs`, `animation_utils.rs`):
  each corner's animation length comes from how well it faces the travel direction
  (front corners instant, back ones `ANIMATION_LENGTH`); moves of <= 2 cells on one line
  use `SHORT_ANIMATION_LENGTH`; critically damped springs, so no overshoot.
- Added on top: `TILT` (-1.0) biases the corners so the bottom edge leads and the top drags.
  Keep |TILT| <= ~1.5, or the whole top edge lags together and the trail becomes a plain slant.
- Tunables at the top of the file: `ANIMATION_LENGTH`, `SHORT_ANIMATION_LENGTH`, `TRAIL_SIZE`
  (Neovide's names and defaults), `TILT`, `FRAME_DT`, `BLINK_DELAY` (<0 disables), `BLINK_PERIOD`.
- A shader only sees the previous and current cursor rect, so a move during an animation
  restarts from the previous cell.

Shader gotchas:
- Uniforms (1.3): `iCurrentCursor`/`iPreviousCursor` (x=left, y=top, z=w, w=h, pixels,
  y up), `iCurrentCursorColor` (alpha = cursor-opacity, use `.rgb`), `iTimeCursorChange`,
  `iFocus`, `iTimeFocus`, `iTime`, `iChannel0`, `iResolution`.
- Ghostty only animates while focused: never animate when `iFocus == 0`, or a
  mid-animation frame freezes on screen.
- `half` is a reserved word. Compile check: look for the `shadertoy` log line.
- Preserve `fragColor.a` (background-opacity); force alpha 1 where the cursor is drawn.
- Smooth scrolling is impossible here: Ghostty scrolls by whole lines and exposes nothing
  about scrolling to shaders.

## Neovim

LazyVim starter (`init.lua`, `lua/config/*.lua`, `lua/plugins/*.lua`, `lazy-lock.json`).
Custom: `lua/plugins/animations.lua`: `smear-cursor.nvim` (off when `TERM=xterm-ghostty`,
since the Ghostty shader animates the cursor) and snacks.nvim smooth scroll (defaults).
`lua/plugins/example.lua` is the inert LazyVim example. No LazyVim extras enabled.
Roll back plugin versions: `:Lazy restore`.

## Launcher, notifications, lock/idle

- fuzzel: monochrome, JetBrainsMono 15; `terminal=ghostty -e` for terminal apps. Also the
  dmenu for clipboard, `powermenu`, `emoji` and `docs`.
- mako: monochrome, 5 s timeout.
- hypridle: on battery only, lock at 5 min, DPMS off at 5.5 min; locks before sleep.
- hyprlock: fingerprint + password, blurred wallpaper, clock.

## Helper scripts (`~/.local/bin`)

| Script | Purpose |
|---|---|
| `sysupdate` | dnf + flatpak + fwupd, snapper snapshots, Hyprland version diff + config check, reboot hint |
| `maintain` | upkeep: `check` (validates every component) / `backups` / `dotfiles` / `update` / `clean` |
| `keys` | SUPER+/ cheatsheet (curses TUI in foot), built from bind descriptions + `EXTRA` |
| `docs` | SUPER+D machine-docs picker, see [Docs viewer](#docs-viewer) |
| `emoji` | SUPER+E picker: copies, and types if `wtype` is installed |
| `powermenu` | lock / suspend / logout / reboot / shutdown |
| `wallpick` | wallpaper picker (fzf + chafa in foot; ~/Pictures + dharmx/walls) → `setbg` |
| `setbg [img]` | point `~/.config/wallpaper` at an image (none = keep current) and (re)start swaybg; autostart runs it |
| `vpn [off\|status]` | openfortivpn (Okta SAML) for the Paris office |
| `webapp-install` / `-remove` | Chromium app-window launchers (gum prompts) |

- Scripts start with a `#` usage header; keep that convention.
- Emoji data: `~/.local/share/emoji/emoji.txt` (`<emoji> <name>`), generated from unicode.org
  `emoji-test.txt` (fully-qualified lines only).

## Docs viewer

`docs` lists fixed entries (`DOCS=("label|target")`): README, this reference, the cheatsheet,
the Omawrite README (SKILL.md is left out: it's instructions for Claude). `.md` opens in a floating foot popup (app-id `docview`,
1100x800): `nvim --clean -R -M --cmd "luafile ~/.config/docview/viewer.lua"`.

`viewer.lua` loads LazyVim's installed `render-markdown.nvim` (anti_conceal off; raw markdown
if the plugin is gone), sets monochrome heading colours (H1–H3 bands `#bababa`, `#cecece`,
`#dedede`) and maps Esc/q to quit.

Gotcha: it's nvim and not bat+less because less can't bind a lone Esc (`\e quit` in lesskey
makes the arrow keys quit too).

## Shell (`~/.bashrc.d`)

Plain bash; Fedora's `~/.bashrc` sources every file in `~/.bashrc.d` (interactive parts
return early for non-interactive shells).
- `dotfiles`: the `dot` alias.
- `prompt`: `folder branch status ❯` (replaces Fedora's `bash-color-prompt`). `PS1='$(__prompt $?)'`;
  one `git status --porcelain=v2 --branch` per prompt (~8 ms). Symbols: `*` unstaged, `+` staged,
  `%` untracked, `↑n`/`↓n` ahead/behind. Arrow green, red after a failure. Colour codes use
  `\001`/`\002` because `\[ \]` aren't honoured inside `$(...)`.
- `tools`: from Omarchy's `default/bash/aliases` + `init`: zoxide (`cd` → `zd`, falls back to
  `builtin cd` for real paths), eza aliases (`ls`/`lsa`/`lt`/`lta`). Each block only activates
  when its tool is installed (`zoxide eza tealdeer yt-dlp` from dnf).
- `functions`: Omarchy's `default/bash/fns/*` (upstream: basecamp/omarchy, branch `quattro`):
  compression, worktrees, ssh-port-forwarding, rsyncing, drives, tmux (`tdl`/`tdlm`/`tsl`, not
  `tds`), ssh-reconnect. Local changes are marked `local:`: no `mise trust` in `ga`; `iso2sd`
  picks the drive with `gum choose`; `tdl` defaults to `claude`, opens `nvim` explicitly
  (`$EDITOR` is nano) and focuses the editor (upstream selects an unset `$opencode_pane`).
- Not taken: fzf `ff`/Ctrl+R bindings, `try`, Herdr, `tds` (needs hunk/opencode), Omarchy's
  other aliases.
- Gotcha: git has no global `user.name`/`user.email` (only the dotfiles repo sets one), so
  commits in other repos fail until it's configured.

## Dotfiles repo

- `git --git-dir=$HOME/.dotfiles --work-tree=$HOME …` (alias `dot`, interactive shells only).
- Remote `origin` = **public** GitHub repo (`gh` CLI, SSH). Push after committing;
  `maintain dotfiles` offers to push unpushed commits. Before tracking a new file, check it
  for secrets and work-internal URLs (Deezer infra, Slack IDs, GCP projects): those stay
  local and go in `info/exclude` (the work webapps and `vpn` script already are).
  Pre-publish history was stripped of them; the original is in
  `~/.local/share/dotfiles-archive/dotfiles-before-github-2026-10-15.bundle`.
- `status.showUntrackedFiles = no`: new files never show in `status`. `maintain dotfiles`
  lists untracked files under the `WATCH=(…)` folders in `maintain` and offers to add them.
  Deliberately untracked files (nvim starter boilerplate, `claude`/`omawrite` binaries, game
  launchers, mime caches) are listed in `~/.dotfiles/info/exclude` (not itself tracked).
- Commit style: `<component>: <change>`, or `Maintenance snapshot YYYY-MM-DD` from maintain.

## System

- Fedora 44, btrfs + snapper (root config), dnf5, flatpak, fwupd.
- Session env goes to systemd (for xdg-desktop-portal) via `hyprland-session.target`.
  XDG autostart (`~/.config/autostart`) is **not** run in this session: autostart lives in
  `hyprland.lua`.
- Wireplumber drop-in: `~/.config/systemd/user/wireplumber.service.d/libcamera-tuning.conf`.
- Display 1920x1200 @ 60 Hz, scale 1.5. Laptop (battery, fingerprint reader, brightness keys).
- **Omawrite** (Omarchy's Qt Markdown writer) is Arch-only upstream, so it's built from
  `~/src/omawrite` with `bin/build` (needs `qt6-qtbase-devel qt6-qtdeclarative-devel gcc-c++
  make`) and installed per user: `~/.local/bin/omawrite`, its `.desktop` file and icon.
  Update: `git -C ~/src/omawrite pull && bin/build`, then copy `build/omawrite` to
  `~/.local/bin`. sysupdate does not update it.
