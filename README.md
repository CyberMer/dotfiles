# Hyprland dotfiles

My Hyprland configuration (Lua config, Hyprland 0.57+) with a macOS-like look, using Dux Shell (`dms`) for the bar, launcher, notifications and lock screen.

## What's inside

| File | Purpose |
|---|---|
| `hyprland.lua` | main config: monitors, look & feel, gestures, keybindings |
| `window-extras.lua` | minimize support for apps' own minimize buttons |
| `tablet.lua` + `scripts/tablet-mode.py` | tablet mode for 2-in-1 laptops: auto-rotation (screen, touch, stylus) from the accelerometer, iPad-style on-screen keyboard ([wvkbd-ipad](https://github.com/CyberMer/wvkbd-ipad)) |
| `hypridle.conf` | idle warning, lock and suspend timers |
| `hyprlock.conf` | lock screen with a random hadith (`scripts/hadiths/`) |
| `scripts/` | screenshot, color picker, screen recording, light/dark appearance sync, AirPods helper keep-alive |
| `wallpapers/` | city and nature wallpapers (Git LFS) |

## Keybindings (highlights)

| Keys | Action |
|---|---|
| `Super + Space` | app launcher |
| `Super + T / E / B / C` | terminal / files / browser / VS Code |
| `Super + N` | control center |
| `Super + O` | workspace overview |
| `Super + S` | screenshot |
| `Super + Tab` | switch keyboard layout (US → FR → AR) |
| `Super + Shift + T` | tablet mode on/off |
| `Super + K` | on-screen keyboard |
| 3-finger swipe | switch workspace / overview |

## Install

```sh
git clone https://github.com/CyberMer/dotfiles ~/.config/hypr
cd ~/.config/hypr && git lfs pull   # wallpapers
```

Machine-specific settings can go in an untracked `local.lua` (loaded if present). The tablet mode targets an HP Spectre x360 (the `HP WMI hotkeys` tablet switch); change `SWITCH_DEVICE` and `OUTPUT` at the top of `scripts/tablet-mode.py` for other devices.
