-- Minimize support (Hyprland has no minimized state):
--  * an app's own minimize button (Brave, VS Code, Electron apps…) sends a request -> the window goes to DMS's hidden area
--  * bringing a hidden window back (Dock click, app switcher…) puts it on the current workspace as a normal window
local function sel(w) return "address:" .. w.address end
local function as_window(w) if type(w) ~= "table" and type(w) ~= "userdata" then return hl.get_active_window() end return w end

hl.on("window.minimize", function(w, state)
    if state == false or state == 0 then return end
    w = as_window(w)
    if not w or not w.workspace or (w.workspace.id or 0) < 1 then return end
    hl.dispatch(hl.dsp.window.move({ workspace = "special:hidden", follow = false, window = sel(w) }))
end)

-- close the hidden area on every screen (with two screens, DMS may open it on one while the window is on the other;
-- a hidden area left open is an invisible dimmed layer that swallows clicks)
local function close_hidden_everywhere()
    for _, m in ipairs(hl.get_monitors()) do
        local s = m.active_special_workspace
        if s and s.name == "special:hidden" then m:set_special_workspace(false) end
    end
end

hl.on("window.active", function(w)
    w = as_window(w)
    if not w or not w.workspace or w.workspace.name ~= "special:hidden" then return end
    local mon = w.monitor or hl.get_active_monitor()
    local ws = mon and mon.active_workspace
    if not ws or not ws.id or ws.id < 1 then return end
    hl.dispatch(hl.dsp.window.move({ workspace = ws.id, window = sel(w) }))
    close_hidden_everywhere()
    hl.dispatch(hl.dsp.focus({ window = sel(w) }))
    -- DMS activates the window a moment after opening the hidden area: sweep again after that
    hl.timer(function() close_hidden_everywhere() end, { timeout = 250, type = "oneshot" })
end)

-- Keys: Super+H minimizes the focused window, Super+Shift+H shows/hides all minimized windows
hl.bind("SUPER + H", function()
    local w = hl.get_active_window()
    if w and w.workspace and (w.workspace.id or 0) >= 1 then
        hl.dispatch(hl.dsp.window.move({ workspace = "special:hidden", follow = false, window = "address:" .. w.address }))
    end
end)
hl.bind("SUPER + SHIFT + H", hl.dsp.workspace.toggle_special("hidden"))
