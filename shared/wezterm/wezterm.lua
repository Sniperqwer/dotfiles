local wezterm = require("wezterm")

local config = wezterm.config_builder()

config.automatically_reload_config = true
config.initial_cols = 120
config.initial_rows = 40
config.enable_tab_bar = true
config.window_close_confirmation = "NeverPrompt"
config.window_decorations = "RESIZE"
config.default_cursor_style = "SteadyBlock"
config.color_scheme = "Nord (Gogh)"
config.font = wezterm.font_with_fallback({
	{ family = "Monaco", weight = "Medium" },
	{ family = "LXGW WenKai Mono", weight = "Medium" },
})
config.font_size = 20
config.window_padding = {
	left = 10,
	right = 10,
	top = 10,
	bottom = 10,
}

-- Load machine-local overrides if present.
local ok, local_overrides = pcall(dofile, os.getenv("HOME") .. "/.config/wezterm/local.lua")
if ok and type(local_overrides) == "function" then
	local_overrides(config)
end

return config
