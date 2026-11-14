hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })

hl.config({
    input = { kb_layout = "us", follow_mouse = 1, sensitivity = 0 },
    general = {
        gaps_in = 5,
        gaps_out = 12,
        border_size = 1,
        col = { active_border = { colors = { "rgba(8998ffff)", "rgba(b18cffdd)" }, angle = 45 }, inactive_border = "rgba(61709a66)" },
        layout = "dwindle",
    },
    decoration = {
        rounding = 14,
        active_opacity = 0.97,
        inactive_opacity = 0.92,
        blur = { enabled = true, size = 8, passes = 3, vibrancy = 0.12 },
    },
    animations = { enabled = true },
    misc = { disable_hyprland_logo = true, disable_splash_rendering = true },
})

hl.curve("glass", { type = "bezier", points = { { 0.2, 0.8 }, { 0.2, 1 } } })
hl.animation({ leaf = "windows", enabled = true, speed = 5, bezier = "glass", style = "popin 85%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 4, bezier = "glass", style = "popin 85%" })
hl.animation({ leaf = "fade", enabled = true, speed = 4, bezier = "glass" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 5, bezier = "glass", style = "slide" })

hl.bind("SUPER + RETURN", hl.dsp.exec_cmd("kitty"))
hl.bind("SUPER + Q", hl.dsp.window.close())
hl.bind("SUPER + M", hl.dsp.exit())
hl.bind("SUPER + F", hl.dsp.window.fullscreen())
hl.bind("SUPER + SPACE", hl.dsp.exec_cmd("hyprctl dispatch global quickshell:glass-launcher-toggle"))
hl.bind("SUPER + 1", hl.dsp.focus({ workspace = 1 }))
hl.bind("SUPER + 2", hl.dsp.focus({ workspace = 2 }))
hl.bind("SUPER + 3", hl.dsp.focus({ workspace = 3 }))
hl.bind("SUPER + 4", hl.dsp.focus({ workspace = 4 }))
hl.bind("SUPER + SHIFT + 1", hl.dsp.window.move({ workspace = 1 }))
hl.bind("SUPER + SHIFT + 2", hl.dsp.window.move({ workspace = 2 }))
hl.bind("SUPER + SHIFT + 3", hl.dsp.window.move({ workspace = 3 }))
hl.bind("SUPER + SHIFT + 4", hl.dsp.window.move({ workspace = 4 }))

hl.on("hyprland.start", function()
    hl.exec_cmd("swaybg -i /usr/share/wojticore-glass/glass-wallpaper.png -m fill")
    hl.exec_cmd("quickshell -p /usr/share/wojticore-glass/Shell.qml")
end)
