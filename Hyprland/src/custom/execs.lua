-- This file will not be overwritten across dots-hyprland updates.
-- The file name is for the sake of organization and does not matter
-- See the corresponding files in ~/.config/hypr/hyprland for examples

hl.on("hyprland.start", function ()
    -- Input method
    hl.exec_cmd("fcitx5 -d")

    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP HYPRLAND_INSTANCE_SIGNATURE DISPLAY")
    hl.exec_cmd("systemctl --user start hyprland-session.target")
end)
