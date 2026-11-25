-- Mode tablette (HP Spectre x360) — voir scripts/tablet-mode.py
-- Replier l'écran = mode tablette automatique (rotation auto + clavier virtuel).

local tablet = os.getenv("HOME") .. "/.config/hypr/scripts/tablet-mode.py"

-- Le tactile et le stylet visent toujours l'écran interne (même avec un écran externe branché)
hl.config({
    input = {
        touchdevice = { output = "eDP-1" },
        tablet      = { output = "eDP-1" },
    },
})

hl.on("hyprland.start", function()
    hl.exec_cmd(tablet .. " daemon")
end)

hl.bind("SUPER + SHIFT + T", hl.dsp.exec_cmd(tablet .. " toggle"))   -- mode tablette on/off (à la main)
hl.bind("SUPER + SHIFT + O", hl.dsp.exec_cmd(tablet .. " lock"))     -- verrouiller la rotation
hl.bind("SUPER + K",         hl.dsp.exec_cmd(tablet .. " keyboard")) -- clavier virtuel

-- Clavier virtuel : fond translucide flouté façon iPadOS (Liquid Glass)
-- + glisse depuis le bas quand il apparaît
hl.layer_rule({ match = { namespace = "wvkbd" }, blur = true, ignore_alpha = 0.1, animation = "slide bottom" })
