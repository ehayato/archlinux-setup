-- This file will not be overwritten across dots-hyprland updates.
-- The file name is for the sake of organization and does not matter
-- See the corresponding files in ~/.config/hypr/hyprland for examples

-- ######## Window rules ########

-- Move Discord / Slack to special workspaces
hl.window_rule({match = {class = "discord" }, workspace = "special:discord"})
hl.window_rule({match = {class = "slack" },   workspace = "special:slack"})

-- Picture-in-Picture (Japanese title)
hl.window_rule({match = {title = "ピクチャーインピクチャー" }, float = true})
hl.window_rule({match = {title = "ピクチャーインピクチャー" }, pin = true})
hl.window_rule({match = {title = "ピクチャーインピクチャー" }, size = {"(monitor_w*0.2)", "(monitor_h*0.2)"}})
hl.window_rule({match = {title = "ピクチャーインピクチャー" }, move = {"(monitor_w*0.75)", "(monitor_h*0.75)"}})

hl.window_rule({match = {class = "org.kde.ark" }, float = true})

-- Pinned windows
hl.window_rule({match = {pin = 1 }, border_color = "rgb(FFB7C5)"})
hl.window_rule({match = {pin = 1 }, border_size = 2})

-- Zoom Meeting
hl.window_rule({match = {class = "^(zoom)$" }, float = true})
hl.window_rule({match = {class = "^(zoom)$" }, suppress_event = "maximize fullscreen"})
