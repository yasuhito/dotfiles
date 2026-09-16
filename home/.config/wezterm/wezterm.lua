local wezterm = require 'wezterm'
local config = wezterm.config_builder()

config.color_scheme = 'flexoki-light'
config.font = wezterm.font_with_fallback {
  { family = 'JetBrainsMono Nerd Font', weight = 'Regular' },
  { family = 'Noto Sans Mono CJK JP', weight = 'Regular' },
}
config.font_size = 9.0
config.enable_tab_bar = false

return config
