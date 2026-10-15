-- Hyprland config — Omarchy-style keybinds, Fedora 44
-- Docs: https://wiki.hypr.land

hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })

local terminal    = "ghostty"
local fileManager = "nautilus"
local browser     = "firefox"
local menu        = "fuzzel"
local mod         = "SUPER"

-- ---------- Autostart ----------
hl.on("hyprland.start", function()
    -- Export session env to systemd/D-Bus and start graphical-session.target (needed by xdg-desktop-portal)
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP HYPRLAND_INSTANCE_SIGNATURE DISPLAY && systemctl --user start hyprland-session.target")
    hl.exec_cmd("waybar")
    hl.exec_cmd("mako")
    hl.exec_cmd("/usr/libexec/polkit-mate-authentication-agent-1")
    hl.exec_cmd("nm-applet --indicator")
    hl.exec_cmd("blueman-applet")
    hl.exec_cmd("wl-paste --watch cliphist store")
    hl.exec_cmd("swaybg -i ~/.config/wallpaper -m fill -c 1e1e2e")
    hl.exec_cmd("hypridle")
    hl.exec_cmd("wlsunset -l 48.9 -L 2.4")
    hl.exec_cmd("/opt/1Password/1password --silent")
    -- Paris VPN (uncomment to connect at login)
    -- hl.exec_cmd("~/.local/bin/vpn")
end)

hl.env("XCURSOR_SIZE", "24")
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
-- XWayland apps render at native res (see xwayland below), so Steam scales its own UI
hl.env("STEAM_FORCE_DESKTOPUI_SCALING", "1.5")

-- ---------- Look ----------
hl.config({
    general = {
        gaps_in = 4,
        gaps_out = 8,
        border_size = 2,
        col = {
            active_border   = "rgba(2c2c2cff)",
            inactive_border = "rgba(babababb)",
        },
        layout = "scrolling",
        resize_on_border = true,
        allow_tearing = true,   -- only for windows with the `immediate` rule (games)
    },

    -- Don't upscale X11 apps (Steam, Celeste) from 1280x800; render them at native 1920x1200
    xwayland = { force_zero_scaling = true },

    decoration = {
        rounding = 0,
        active_opacity = 1.0,
        inactive_opacity = 0.88,
        shadow = {
            enabled = true,
            range = 6,
            render_power = 3,
            color = "rgba(2c2c2c44)",
        },
        blur = {
            enabled = true,
            size = 4,
            passes = 2,
        },
    },

    animations = { enabled = true },

    dwindle = { preserve_split = true },

    -- Niri-style scrollable columns
    scrolling = {
        column_width = 0.5,
        explicit_column_widths = "0.333, 0.5, 0.667, 1.0",
        fullscreen_on_one_column = true,
        focus_fit_method = 1,     -- 1 = fit, 0 = center
        follow_focus = true,
        wrap_focus = false,
        wrap_swapcol = false,
    },

    misc = {
        disable_hyprland_logo = true,
        disable_splash_rendering = true,
        disable_hyprland_guiutils_check = true, -- guiutils is not packaged for Fedora; silences the launch warning
    },

    -- ---------- Input ----------
    input = {
        kb_layout = "us",
        kb_variant = "altgr-intl",
        follow_mouse = 1,
        sensitivity = 0,
        touchpad = {
            natural_scroll = true,
            tap_to_click = true,
        },
    },
})

-- everything off except focus changes and window open/close (workspaces stay instant)
hl.curve("ease", { type = "bezier", points = { {0.25, 1}, {0.5, 1} } })
hl.animation({ leaf = "global",      enabled = false })
hl.animation({ leaf = "fadeSwitch",  enabled = true, speed = 4, bezier = "default" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 4, bezier = "ease" })
hl.animation({ leaf = "border",      enabled = true, speed = 6, bezier = "default" })
hl.animation({ leaf = "windowsIn",   enabled = true, speed = 4, bezier = "ease", style = "popin 85%" })
hl.animation({ leaf = "windowsOut",  enabled = true, speed = 4, bezier = "ease", style = "popin 85%" })
hl.animation({ leaf = "fadeIn",      enabled = true, speed = 4, bezier = "default" })
hl.animation({ leaf = "fadeOut",     enabled = true, speed = 4, bezier = "default" })

hl.gesture({ fingers = 3, direction = "horizontal", action = "scroll_move" })
hl.gesture({ fingers = 3, direction = "vertical",   action = "workspace" })

-- ---------- Keybinds (Omarchy-style) ----------
local function bind(keys, dsp, opts) hl.bind(mod .. " + " .. keys, dsp, opts) end

bind("RETURN",         hl.dsp.exec_cmd(terminal))
bind("SPACE",          hl.dsp.exec_cmd(menu))
bind("W",              hl.dsp.window.close())
bind("F",              hl.dsp.window.fullscreen())
bind("T",              hl.dsp.window.float({ action = "toggle" }))
bind("P",              hl.dsp.window.pseudo())
bind("SHIFT + F",      hl.dsp.exec_cmd(fileManager))
bind("SHIFT + B",      hl.dsp.exec_cmd(browser))
bind("SHIFT + O",      hl.dsp.exec_cmd("~/.local/bin/omawrite"))
bind("ESCAPE",         hl.dsp.exec_cmd("~/.local/bin/powermenu"))
bind("L",              hl.dsp.exec_cmd("loginctl lock-session"))
bind("SHIFT + ESCAPE", hl.dsp.exit())
bind("CTRL + V",       hl.dsp.exec_cmd("cliphist list | fuzzel --dmenu --prompt 'clipboard  ›  ' --width 60 | cliphist decode | wl-copy"))
bind("SHIFT + W",      hl.dsp.exec_cmd("~/.local/bin/wallpick"))
bind("E",              hl.dsp.exec_cmd("~/.local/bin/emoji"))
bind("SLASH",          hl.dsp.exec_cmd("~/.local/bin/keys"))

-- Universal clipboard: works in terminals and GUI apps alike
-- (Ctrl+Insert / Shift+Insert are copy/paste in both)
bind("C", hl.dsp.send_shortcut({ mods = "CTRL",  key = "Insert" }))
bind("V", hl.dsp.send_shortcut({ mods = "SHIFT", key = "Insert" }))
bind("X", hl.dsp.send_shortcut({ mods = "CTRL",  key = "X" }))

-- Screenshots
hl.bind("PRINT",         hl.dsp.exec_cmd('grim -g "$(slurp)" - | swappy -f -'))
hl.bind("SHIFT + PRINT", hl.dsp.exec_cmd("grim - | wl-copy"))

-- Focus
bind("LEFT",  hl.dsp.focus({ direction = "left" }))
bind("RIGHT", hl.dsp.focus({ direction = "right" }))
bind("UP",    hl.dsp.focus({ direction = "up" }))
bind("DOWN",  hl.dsp.focus({ direction = "down" }))

bind("HOME", hl.dsp.layout("focus tobeg"))
bind("END",  hl.dsp.layout("focus toend"))

-- Move windows (between/within columns)
bind("SHIFT + LEFT",  hl.dsp.layout("swapcol l"))
bind("SHIFT + RIGHT", hl.dsp.layout("swapcol r"))
bind("SHIFT + UP",    hl.dsp.window.move({ direction = "up" }))
bind("SHIFT + DOWN",  hl.dsp.window.move({ direction = "down" }))

-- Move whole columns
bind("CTRL + LEFT",  hl.dsp.layout("swapcol l"))
bind("CTRL + RIGHT", hl.dsp.layout("swapcol r"))

-- Consume / expel windows into / out of columns
bind("BRACKETLEFT",  hl.dsp.layout("consume_or_expel prev"))
bind("BRACKETRIGHT", hl.dsp.layout("consume_or_expel next"))
bind("COMMA",        hl.dsp.layout("consume"))
bind("PERIOD",       hl.dsp.layout("expel"))

-- Column width
bind("R",             hl.dsp.layout("colresize +conf"))
bind("SHIFT + R",     hl.dsp.layout("colresize -conf"))
bind("M",             hl.dsp.layout("colresize 1.0"))
bind("SHIFT + C",     hl.dsp.layout("fit active"))
bind("MINUS",         hl.dsp.layout("colresize -0.1"))
bind("EQUAL",         hl.dsp.layout("colresize +0.1"))
bind("SHIFT + MINUS", hl.dsp.window.resize({ x = 0, y = -60, relative = true }))
bind("SHIFT + EQUAL", hl.dsp.window.resize({ x = 0, y = 60, relative = true }))

-- Workspaces
for i = 1, 9 do
    bind(tostring(i),           hl.dsp.focus({ workspace = i }))
    bind("SHIFT + " .. i,       hl.dsp.window.move({ workspace = i }))
end
bind("TAB",         hl.dsp.focus({ workspace = "e+1" }))
bind("SHIFT + TAB", hl.dsp.focus({ workspace = "e-1" }))
bind("mouse_down",  hl.dsp.focus({ workspace = "e+1" }))
bind("mouse_up",    hl.dsp.focus({ workspace = "e-1" }))

-- Mouse move/resize
bind("mouse:272", hl.dsp.window.drag(),   { mouse = true })
bind("mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Media / brightness keys
local repeatLocked = { locked = true, repeating = true }
hl.bind("XF86AudioRaiseVolume",  hl.dsp.exec_cmd("wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+"), repeatLocked)
hl.bind("XF86AudioLowerVolume",  hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),        repeatLocked)
hl.bind("XF86AudioMute",         hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),       repeatLocked)
hl.bind("XF86AudioMicMute",      hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),     repeatLocked)
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("brightnessctl s 5%+"),                              repeatLocked)
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl s 5%-"),                              repeatLocked)
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"),   { locked = true })

-- Wallpaper picker (wallpick) as a centered floating window
hl.window_rule({
    name   = "wallpick",
    match  = { class = "^(wallpick)$" },
    float  = true,
    size   = { 1500, 820 },
    center = true,
})

-- Celeste: present frames immediately (tearing) instead of waiting for vsync — lower input lag
hl.window_rule({
    name      = "celeste-tearing",
    match     = { class = "^([Cc]eleste)$" },
    immediate = true,
})

-- Shortcut cheatsheet (keys) as a centered floating window
hl.window_rule({
    name   = "keys",
    match  = { class = "^(keys)$" },
    float  = true,
    size   = { 900, 700 },
    center = true,
})

-- Omawrite: slightly see-through (blurred) like the terminal
hl.window_rule({
    name    = "omawrite-opacity",
    match   = { class = "^(omawrite)$" },
    opacity = "0.92 0.85",
})
