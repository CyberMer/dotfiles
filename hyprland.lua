-- Hyprland config (Lua) — shell: Dux Shell (dms)
-- Docs: https://wiki.hypr.land

local mainMod = "SUPER"

------------------
---- MONITORS ----
------------------

-- Desk monitors (G15 Strix)
hl.monitor({ output = "DP-3",  mode = "preferred", position = "auto-left", scale = "1" })
hl.monitor({ output = "DP-4",  mode = "preferred", position = "auto-left", scale = "1" })
hl.monitor({ output = "eDP-1", mode = "preferred", position = "auto",      scale = "1" })
-- Any other monitor (e.g. DP-2)
hl.monitor({ output = "",      mode = "preferred", position = "auto",      scale = "1" })

-------------------
---- AUTOSTART ----
-------------------

hl.on("hyprland.start", function()
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
    hl.exec_cmd("systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
    hl.exec_cmd("dms run")  -- Dux Shell — bar, control center, notifications, launcher, wallpaper, lock screen
    -- macOS look: apps and terminal follow light/dark mode
    hl.exec_cmd(os.getenv("HOME") .. "/.config/hypr/scripts/mac-appearance.sh")
    hl.exec_cmd(os.getenv("HOME") .. "/.config/hypr/scripts/librepods-keepalive.sh") -- AirPods support (restarts librepods if it crashes)

end)

-------------------
---- ENVIRONMENT --
-------------------

hl.env("QT_QPA_PLATFORM", "wayland")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("XCURSOR_THEME", "macOS")
hl.env("HYPRCURSOR_THEME", "macOS")
-- Qt apps use the macOS (Kvantum) theme
if io.open("/usr/bin/qt6ct") then hl.env("QT_QPA_PLATFORMTHEME", "qt6ct") end
if io.open("/usr/bin/kvantummanager") then hl.env("QT_STYLE_OVERRIDE", "kvantum") end

---------------------
---- LOOK & FEEL ----
---------------------

-- macOS look: no colored border, just a hairline + soft drop shadow
hl.config({
    general = {
        gaps_in = 6,
        gaps_out = 12,
        border_size = 1,
        col = {
            active_border = "rgba(ffffff2e)",
            inactive_border = "rgba(ffffff14)",
        },
        layout = "dwindle",
        resize_on_border = true,
    },
    decoration = {
        rounding = 12,
        active_opacity = 1.0,
        inactive_opacity = 1.0,
        shadow = {
            enabled = true,
            range = 40,
            render_power = 3,
            offset = "0 12",
            color = "rgba(00000073)",
            color_inactive = "rgba(00000040)",
        },
        blur = {
            enabled = true,
            size = 10,
            passes = 3,
            noise = 0.02,
            vibrancy = 0.25,
        },
    },
    animations = {
        enabled = true,
    },
    dwindle = {
        preserve_split = true,
    },
    misc = {
        disable_hyprland_logo = true,
    },
})

-- macOS-like motion: quick ease-out, windows scale in, Spaces slide sideways
hl.curve("macEase",  { type = "bezier", points = { { 0.25, 1 }, { 0.5, 1 } } })
hl.curve("macSpace", { type = "bezier", points = { { 0.2, 0.9 }, { 0.2, 1 } } })
hl.animation({ leaf = "windows",    enabled = true, speed = 4,  bezier = "macEase", style = "popin 92%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 3,  bezier = "macEase", style = "popin 92%" })
hl.animation({ leaf = "border",     enabled = true, speed = 6,  bezier = "default" })
hl.animation({ leaf = "fade",       enabled = true, speed = 4,  bezier = "macEase" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 5,  bezier = "macSpace", style = "slide" })

---------------
---- INPUT ----
---------------

hl.config({
    input = {
        kb_layout = "us,fr,ara", -- SUPER+TAB cycles: US → French AZERTY → Arabic
        follow_mouse = 1,
        sensitivity = 0,
        touchpad = {
            natural_scroll = false,
        },
    },
})

-- Touchpad gestures (3 fingers)
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })              -- swipe: change workspace
hl.gesture({ fingers = 3, direction = "down", mods = "ALT", action = "close" })           -- ALT + swipe down: close window
hl.gesture({ fingers = 3, direction = "up", mods = "SUPER", scale = 1.5, action = "fullscreen" }) -- SUPER + swipe up: fullscreen
-- Swipe up: overview of all workspaces and open windows (like Windows Task View); swipe down: close it
hl.gesture({ fingers = 3, direction = "up",   action = function() hl.exec_cmd("dms ipc call hypr openOverview") end })
hl.gesture({ fingers = 3, direction = "down", action = function() hl.exec_cmd("dms ipc call hypr closeOverview") end })

----------------------
---- WINDOW RULES ----
----------------------

-- Ignore apps asking to open maximized (kitty does) — let tiling decide the size
hl.window_rule({ name = "suppress-maximize-events", match = { class = ".*" }, suppress_event = "maximize" })

hl.window_rule({ name = "float-pavucontrol", match = { class = "^(org.pulseaudio.pavucontrol|pavucontrol)$" }, float = true })
hl.window_rule({ name = "float-blueman",     match = { class = "^(.blueman-manager-wrapped|blueman-manager)$" }, float = true })
hl.window_rule({ name = "float-file-dialogs", match = { title = "^(Open File|Open Files|Save File|Save As|Open Folder|Select a File|File Upload)(.*)$" }, float = true })
hl.window_rule({ name = "pip",               match = { title = "^(Picture.in.[Pp]icture)$" }, float = true, pin = true })

hl.layer_rule({ match = { namespace = "dms" }, no_anim = true })

---------------------
---- KEYBINDINGS ----
---------------------

-- Apps
hl.bind(mainMod .. " + T", hl.dsp.exec_cmd("kitty"))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd("thunar"))
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd("brave"))
hl.bind(mainMod .. " + C", hl.dsp.exec_cmd("code"))

-- Dux Shell
hl.bind(mainMod .. " + SPACE",     hl.dsp.exec_cmd("dms ipc call spotlight toggle"))       -- app launcher
hl.bind(mainMod .. " + N",         hl.dsp.exec_cmd("dms ipc call control-center toggle"))
hl.bind(mainMod .. " + SHIFT + N", hl.dsp.exec_cmd("dms ipc call notifications toggle"))
hl.bind(mainMod .. " + SHIFT + V", hl.dsp.exec_cmd("dms ipc call clipboard toggle"))
hl.bind(mainMod .. " + comma",     hl.dsp.exec_cmd("dms ipc call settings toggle"))
hl.bind(mainMod .. " + O",         hl.dsp.exec_cmd("dms ipc call hypr toggleOverview"))    -- workspace overview
hl.bind(mainMod .. " + slash",     hl.dsp.exec_cmd("dms ipc call keybinds toggle"))        -- keybind cheatsheet
hl.bind(mainMod .. " + W",         hl.dsp.exec_cmd("dms ipc call wallpaper next"))         -- next wallpaper
hl.bind(mainMod .. " + L",         hl.dsp.exec_cmd("dms ipc call lock lock"))              -- lock screen
hl.bind(mainMod .. " + M",         hl.dsp.exec_cmd("dms ipc call powermenu toggle"))       -- power menu
hl.bind(mainMod .. " + SHIFT + M", hl.dsp.exit())                                          -- quit Hyprland

-- Tools (scripts/)
hl.bind(mainMod .. " + S",         hl.dsp.exec_cmd("~/.config/hypr/scripts/screenshot.sh"))
hl.bind(mainMod .. " + P",         hl.dsp.exec_cmd("~/.config/hypr/scripts/colorpicker.sh"))
hl.bind(mainMod .. " + R",         hl.dsp.exec_cmd("~/.config/hypr/scripts/start-recording.sh"))
hl.bind(mainMod .. " + SHIFT + R", hl.dsp.exec_cmd("~/.config/hypr/scripts/stop-recording.sh"))

-- Keyboard layout (all keyboards)
hl.bind(mainMod .. " + TAB", hl.dsp.exec_cmd("hyprctl switchxkblayout all next"))

-- Windows
hl.bind(mainMod .. " + SHIFT + X", hl.dsp.window.close())
hl.bind(mainMod .. " + V",         hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + F",         hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))
hl.bind(mainMod .. " + J",         hl.dsp.layout("togglesplit"))  -- flip split direction

hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down" }))

hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true }) -- SUPER + left-drag: move
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true }) -- SUPER + right-drag: resize

-- Workspaces: SUPER+[1-0] go to, SUPER+SHIFT+[1-0] move window to
for i = 1, 10 do
    local key = tostring(i % 10)
    hl.bind(mainMod .. " + " .. key,         hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

-- Scratchpad: hidden workspace that pops over everything
-- Uses Hyprland's default "special" workspace, the same one Dux's "Move to scratchpad" menu uses
hl.bind(mainMod .. " + grave",         hl.dsp.workspace.toggle_special("special"))
hl.bind(mainMod .. " + SHIFT + grave", hl.dsp.window.move({ workspace = "special:special" }))

-- Media & hardware keys (work on the lock screen too)
hl.bind("XF86AudioRaiseVolume",  hl.dsp.exec_cmd("dms ipc call audio increment 5"),      { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume",  hl.dsp.exec_cmd("dms ipc call audio decrement 5"),      { locked = true, repeating = true })
hl.bind("XF86AudioMute",         hl.dsp.exec_cmd("dms ipc call audio mute"),             { locked = true })
hl.bind("XF86AudioMicMute",      hl.dsp.exec_cmd("dms ipc call audio micmute"),          { locked = true })
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("dms ipc call brightness increment 5"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("dms ipc call brightness decrement 5"), { locked = true, repeating = true })
hl.bind("XF86KbdBrightnessUp",   hl.dsp.exec_cmd("brightnessctl -d smc::kbd_backlight set +1"), { locked = true, repeating = true })
hl.bind("XF86KbdBrightnessDown", hl.dsp.exec_cmd("brightnessctl -d smc::kbd_backlight set 1-"), { locked = true, repeating = true })
hl.bind("XF86AudioPlay",         hl.dsp.exec_cmd("dms ipc call mpris playPause"),        { locked = true })
hl.bind("XF86AudioNext",         hl.dsp.exec_cmd("dms ipc call mpris next"),             { locked = true })
hl.bind("XF86AudioPrev",         hl.dsp.exec_cmd("dms ipc call mpris previous"),         { locked = true })

-- Minimize support for apps' own minimize buttons (see window-extras.lua)
require("window-extras")


-- Tablet mode: auto-rotation, on-screen keyboard (see tablet.lua)
require("tablet")

-- Machine-specific extras, kept out of the repo (optional local.lua)
pcall(require, "local")
