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
    hl.exec_cmd("~/.local/bin/setbg")   -- wallpaper (~/.config/wallpaper)
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
-- desc = cheatsheet entry "Section|What it does[|key label]". ~/.local/bin/keys
-- (SUPER+/) lists every bind that has one, live from `hyprctl binds -j`; binds
-- sharing one cheatsheet line (arrows, C/X/V…) describe only the first.
local function key(keys, dsp, desc, opts)
    local o = { description = desc }
    for k, v in pairs(opts or {}) do o[k] = v end
    hl.bind(keys, dsp, o)
end
local function bind(keys, dsp, desc, opts) key(mod .. " + " .. keys, dsp, desc, opts) end

bind("RETURN",         hl.dsp.exec_cmd(terminal), "Apps|Terminal (ghostty)")
bind("SPACE",          hl.dsp.exec_cmd(menu), "Apps|App launcher (fuzzel)")
bind("W",              hl.dsp.window.close(), "Windows|Close window")
bind("F",              hl.dsp.window.fullscreen(), "Windows|Fullscreen")
bind("T",              hl.dsp.window.float({ action = "toggle" }), "Windows|Toggle floating")
bind("P",              hl.dsp.window.pseudo(), "Windows|Pseudo-tile")
bind("SHIFT + F",      hl.dsp.exec_cmd(fileManager), "Apps|File manager (nautilus)")
bind("SHIFT + B",      hl.dsp.exec_cmd(browser), "Apps|Browser (firefox)")
bind("SHIFT + O",      hl.dsp.exec_cmd("~/.local/bin/omawrite"), "Apps|Markdown writer (omawrite)")
bind("ESCAPE",         hl.dsp.exec_cmd("~/.local/bin/powermenu"), "Session|Power menu")
bind("L",              hl.dsp.exec_cmd("loginctl lock-session"), "Session|Lock screen")
bind("SHIFT + ESCAPE", hl.dsp.exit(), "Session|Exit Hyprland")
bind("CTRL + V",       hl.dsp.exec_cmd("cliphist list | fuzzel --dmenu --prompt 'clipboard  ›  ' --width 60 | cliphist decode | wl-copy"), "Apps|Clipboard history")
bind("SHIFT + W",      hl.dsp.exec_cmd("~/.local/bin/wallpick"), "Apps|Wallpaper picker")
bind("E",              hl.dsp.exec_cmd("~/.local/bin/emoji"), "Apps|Emoji picker")
bind("D",              hl.dsp.exec_cmd("~/.local/bin/docs"), "Apps|Machine docs")
bind("SLASH",          hl.dsp.exec_cmd("~/.local/bin/keys"), "Apps|This cheatsheet")

-- Universal clipboard: works in terminals and GUI apps alike
-- (Ctrl+Insert / Shift+Insert are copy/paste in both)
bind("C", hl.dsp.send_shortcut({ mods = "CTRL",  key = "Insert" }), "Apps|Copy / Cut / Paste (everywhere)|Super + C / X / V")
bind("V", hl.dsp.send_shortcut({ mods = "SHIFT", key = "Insert" }))
bind("X", hl.dsp.send_shortcut({ mods = "CTRL",  key = "X" }))

-- Screenshots
key("PRINT",         hl.dsp.exec_cmd('grim -g "$(slurp)" - | swappy -f -'), "Screenshots|Region → edit in swappy")
key("SHIFT + PRINT", hl.dsp.exec_cmd("grim - | wl-copy"), "Screenshots|Full screen → clipboard")

-- Focus
bind("LEFT",  hl.dsp.focus({ direction = "left" }), "Focus|Focus left / right / up / down|Super + Arrows")
bind("RIGHT", hl.dsp.focus({ direction = "right" }))
bind("UP",    hl.dsp.focus({ direction = "up" }))
bind("DOWN",  hl.dsp.focus({ direction = "down" }))

bind("HOME", hl.dsp.layout("focus tobeg"), "Focus|Focus first column")
bind("END",  hl.dsp.layout("focus toend"), "Focus|Focus last column")

-- Move windows (between/within columns)
bind("SHIFT + LEFT",  hl.dsp.layout("swapcol l"), "Move|Swap column left / right|Super + Shift + Left/Right")
bind("SHIFT + RIGHT", hl.dsp.layout("swapcol r"))
bind("SHIFT + UP",    hl.dsp.window.move({ direction = "up" }), "Move|Move window up / down|Super + Shift + Up/Down")
bind("SHIFT + DOWN",  hl.dsp.window.move({ direction = "down" }))

-- Move whole columns
bind("CTRL + LEFT",  hl.dsp.layout("swapcol l"), "Move|Swap column left / right|Super + Ctrl + Left/Right")
bind("CTRL + RIGHT", hl.dsp.layout("swapcol r"))

-- Consume / expel windows into / out of columns
bind("BRACKETLEFT",  hl.dsp.layout("consume_or_expel prev"), "Move|Consume or expel (previous)")
bind("BRACKETRIGHT", hl.dsp.layout("consume_or_expel next"), "Move|Consume or expel (next)")
bind("COMMA",        hl.dsp.layout("consume"), "Move|Consume window into column")
bind("PERIOD",       hl.dsp.layout("expel"), "Move|Expel window from column")

-- Column width
bind("R",             hl.dsp.layout("colresize +conf"), "Column size|Next preset width")
bind("SHIFT + R",     hl.dsp.layout("colresize -conf"), "Column size|Previous preset width")
bind("M",             hl.dsp.layout("colresize 1.0"), "Column size|Maximize column width")
bind("SHIFT + C",     hl.dsp.layout("fit active"), "Column size|Fit active column")
bind("MINUS",         hl.dsp.layout("colresize -0.1"), "Column size|Width -10% / +10%|Super + - / =")
bind("EQUAL",         hl.dsp.layout("colresize +0.1"))
bind("SHIFT + MINUS", hl.dsp.window.resize({ x = 0, y = -60, relative = true }), "Column size|Height -60px / +60px|Super + Shift + - / =")
bind("SHIFT + EQUAL", hl.dsp.window.resize({ x = 0, y = 60, relative = true }))

-- Workspaces
for i = 1, 9 do
    bind(tostring(i),           hl.dsp.focus({ workspace = i }),
         i == 1 and "Workspaces|Go to workspace|Super + 1-9" or nil)
    bind("SHIFT + " .. i,       hl.dsp.window.move({ workspace = i }),
         i == 1 and "Workspaces|Move window to workspace|Super + Shift + 1-9" or nil)
end
bind("TAB",         hl.dsp.focus({ workspace = "e+1" }), "Workspaces|Next workspace")
bind("SHIFT + TAB", hl.dsp.focus({ workspace = "e-1" }), "Workspaces|Previous workspace")
bind("mouse_down",  hl.dsp.focus({ workspace = "e+1" }), "Workspaces|Cycle workspaces|Super + Scroll")
bind("mouse_up",    hl.dsp.focus({ workspace = "e-1" }))

-- Mouse move/resize
bind("mouse:272", hl.dsp.window.drag(),   "Windows|Move window|Super + Left click drag",    { mouse = true })
bind("mouse:273", hl.dsp.window.resize(), "Windows|Resize window|Super + Right click drag", { mouse = true })

-- Media / brightness keys
local repeatLocked = { locked = true, repeating = true }
key("XF86AudioRaiseVolume",  hl.dsp.exec_cmd("wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+"), "Media|Volume up / down / mute|Volume keys", repeatLocked)
hl.bind("XF86AudioLowerVolume",  hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),        repeatLocked)
hl.bind("XF86AudioMute",         hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),       repeatLocked)
key("XF86AudioMicMute",      hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),     "Media|Mute microphone|Mic mute key", repeatLocked)
key("XF86MonBrightnessUp",   hl.dsp.exec_cmd("brightnessctl s 5%+"),                              "Media|Brightness up / down|Brightness keys", repeatLocked)
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl s 5%-"),                              repeatLocked)
key("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), "Media|Media control|Play / Next / Prev", { locked = true })
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

-- Machine docs viewer (docs → nvim in foot) as a centered floating window
hl.window_rule({
    name   = "docview",
    match  = { class = "^(docview)$" },
    float  = true,
    size   = { 1100, 800 },
    center = true,
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
