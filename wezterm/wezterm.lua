local wezterm = require 'wezterm'

local config = wezterm.config_builder()

-- config.color_scheme = 'One Dark (Gogh)'
config.color_scheme = 'One Half Black (Gogh)'
config.use_fancy_tab_bar = false
-- config.window_background_opacity = 0.9
-- config.text_background_opacity = 0.9

-- English!
-- 中文你好
config.font = wezterm.font 'Monaspace Argon'

return config

