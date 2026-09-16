-- Omarchy's terminal rule currently matches WezTerm's executable name, while
-- native Wayland windows use this app-id. Keep its shared terminal behavior.
o.window("org\\.wezfurlong\\.wezterm", { tag = "+terminal" })

-- Keep every application fully opaque, overriding Omarchy's default opacity.
o.window(".*", { opacity = "1 1 override" })
