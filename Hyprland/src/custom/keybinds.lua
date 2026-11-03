-- This file will not be overwritten across dots-hyprland updates.
-- The file name is for the sake of organization and does not matter
-- See the corresponding files in ~/.config/hypr/hyprland for examples

--##! Shell
-- Interrupt "search on Super release" when Super is used together with another key.
-- Lua port of `binditn = Super, catchall, ...` from the old keybinds.conf
-- (catchall only works inside an active submap, so bind every keycode except Super_L/Super_R instead)
local searchInterrupt = hl.dsp.global("quickshell:searchToggleReleaseInterrupt")
for code = 9, 255 do
    if code ~= 133 and code ~= 134 then
        hl.bind("SUPER + code:" .. code, searchInterrupt, { ignore_mods = true, transparent = true, non_consuming = true })
    end
end
hl.bind("CTRL + SUPER_L", searchInterrupt)
hl.bind("CTRL + SUPER_R", searchInterrupt)
for _, btn in ipairs({ "mouse:272", "mouse:273", "mouse:274", "mouse:275", "mouse:276", "mouse:277", "mouse_up", "mouse_down" }) do
    hl.bind("SUPER + " .. btn, searchInterrupt, { non_consuming = true })
end

--#! User
hl.bind("CTRL + SUPER + Slash", hl.dsp.exec_cmd("xdg-open ~/.config/illogical-impulse/config.json"), { description = "Edit shell config" })
hl.bind("CTRL + SUPER + ALT + Slash", hl.dsp.exec_cmd("xdg-open ~/.config/hypr/custom/keybinds.lua"), { description = "Edit extra keybinds" })

--##! Apps
hl.unbind("SUPER + B") -- Remove default sidebar toggle
hl.bind("SUPER + B", hl.dsp.exec_cmd("~/.config/hypr/hyprland/scripts/launch_first_available.sh \"zen-browser\" \"firefox\" \"google-chrome-stable\" \"brave\" \"chromium\" \"microsoft-edge-stable\" \"opera\" \"librewolf\""), { description = "Browser" })

hl.bind("SUPER + SHIFT + V", hl.dsp.exec_cmd([[bash -c 'result=$(protonvpn connect | grep -oP "[\w ]+(?=\.)" | head -1); notify-send --app-name="ProtonVPN" "ProtonVPN" "$resultサーバーに接続しました。";']]), { description = "ProtonVPN connect" })

hl.bind("SUPER + SHIFT + D", hl.dsp.workspace.toggle_special("discord"), { description = "Toggle Discord workspace" })
hl.unbind("SUPER + SHIFT + S") -- Move default region screenshot to Shift+Print
hl.bind("SUPER + SHIFT + S", hl.dsp.workspace.toggle_special("slack"), { description = "Toggle Slack workspace" })

--##! Utilities
hl.bind("SHIFT + Print", hl.dsp.global("quickshell:regionScreenshot"), { description = "Utilities: Screen snip" })
hl.bind("SHIFT + Print",
    hl.dsp.exec_cmd("qs -c $qsConfig ipc call TEST_ALIVE || pidof slurp || hyprshot --freeze --clipboard-only --mode region --silent"))

hl.bind("SUPER + Space", hl.dsp.window.float({ action = "toggle" }), { description = "Toggle floating for the focused window" })
