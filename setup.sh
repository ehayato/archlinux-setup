#!/usr/bin/env bash
# archlinux-setup: post-install setup
#
# 01_base-install.md (and optionally Hyprland/01_install.md) must be done first.
# Applies 02_setup.md and Hyprland/02_setup.md in one go. Safe to re-run:
# every step skips what is already applied and backs up files it replaces.
#
# Usage:
#   ./setup.sh              # run all steps
#   ./setup.sh shell fcitx5 # run only the named steps
#   ./setup.sh --list       # list steps
#
# Options (environment variables):
#   DUAL_BOOT=0     do not switch the RTC to local time (default: 1)
#   KITTY_SHELL=... shell started by kitty (default: zsh)

set -euo pipefail

REPO_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
DUAL_BOOT=${DUAL_BOOT:-1}
KITTY_SHELL=${KITTY_SHELL:-zsh}
STAMP=$(date +%Y%m%d%H%M%S)

STEPS=(packages system shell fcitx5 hyprland)

PACKAGES=(
    # Shell / terminal
    zsh fzf starship kitty
    # Fonts
    noto-fonts-cjk noto-fonts-emoji ttf-jetbrains-mono-nerd
    # Japanese input
    fcitx5 fcitx5-mozc fcitx5-gtk fcitx5-qt fcitx5-configtool
    # Hardware
    brightnessctl fprintd power-profiles-daemon
    # Audio
    pipewire pipewire-pulse wireplumber
    # Apps
    nemo
    firefox zen-browser-bin google-chrome
    docker docker-compose visual-studio-code-bin github-cli
    proton-vpn-cli proton-pass-bin
    discord slack-desktop
    vlc obs-studio
)

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

log()  { printf '\n\e[1;36m==> %s\e[0m\n' "$*"; }
info() { printf '    %s\n' "$*"; }
warn() { printf '\e[1;33m  ! %s\e[0m\n' "$*" >&2; }

# Copy src to dst unless identical; back up an existing dst first.
# install_file <src> <dst> [sudo]
install_file() {
    local src=$1 dst=$2 run=${3:-}
    if [[ -f $dst ]] && cmp -s "$src" "$dst"; then
        info "up to date: $dst"
        return
    fi
    if [[ -f $dst ]]; then
        $run cp -a "$dst" "$dst.bak.$STAMP"
        info "backup: $dst.bak.$STAMP"
    fi
    $run install -Dm644 "$src" "$dst"
    info "installed: $dst"
}

# Append a line to a file if no identical line exists.
# append_once <file> <line> [sudo]
append_once() {
    local file=$1 line=$2 run=${3:-}
    if [[ -f $file ]] && grep -qxF -- "$line" "$file"; then
        info "already set: $line ($file)"
        return
    fi
    printf '%s\n' "$line" | $run tee -a "$file" >/dev/null
    info "added: $line ($file)"
}

# Insert "auth sufficient pam_fprintd.so" before the first auth line.
add_pam_fprintd() {
    local file=$1
    if [[ ! -f $file ]]; then
        warn "not found, skipped: $file"
        return
    fi
    if grep -q '^auth[[:space:]]\+sufficient[[:space:]]\+pam_fprintd.so' "$file"; then
        info "already set: pam_fprintd ($file)"
        return
    fi
    sudo cp -a "$file" "$file.bak.$STAMP"
    sudo sed -i '0,/^auth/{s/^auth/auth sufficient pam_fprintd.so\nauth/}' "$file"
    info "added: pam_fprintd ($file)"
}

in_hyprland() { [[ -n ${HYPRLAND_INSTANCE_SIGNATURE:-} ]]; }

# ---------------------------------------------------------------------------
# Steps
# ---------------------------------------------------------------------------

step_packages() {
    log "packages: yay"
    if ! command -v yay >/dev/null; then
        sudo pacman -S --needed --noconfirm git base-devel
        local tmp
        tmp=$(mktemp -d)
        git clone https://aur.archlinux.org/yay.git "$tmp/yay"
        (cd "$tmp/yay" && makepkg -si --noconfirm)
        rm -rf "$tmp"
    else
        info "already installed: yay"
    fi

    log "packages: microcode"
    case $(grep -m1 vendor_id /proc/cpuinfo | awk '{print $3}') in
        GenuineIntel) PACKAGES+=(intel-ucode) ;;
        AuthenticAMD) PACKAGES+=(amd-ucode) ;;
    esac

    log "packages: install"
    yay -S --needed --noconfirm "${PACKAGES[@]}"
}

step_system() {
    if [[ $DUAL_BOOT == 1 ]]; then
        log "system: RTC in local time (Windows dual boot)"
        sudo timedatectl set-local-rtc 1
        sudo timedatectl set-ntp true
    fi

    log "system: power button / lid"
    install_file "$REPO_DIR/src/systemd/power-key.conf" /etc/systemd/logind.conf.d/power-key.conf sudo
    install_file "$REPO_DIR/src/systemd/hibernate-delay.conf" /etc/systemd/sleep.conf.d/hibernate-delay.conf sudo
    # Reload instead of restart: restarting logind can kill the session
    sudo systemctl kill -s HUP systemd-logind

    log "system: fingerprint (PAM)"
    add_pam_fprintd /etc/pam.d/system-auth
    add_pam_fprintd /etc/pam.d/login

    log "system: input method"
    append_once /etc/environment 'XMODIFIERS=@im=fcitx' sudo

    log "system: docker"
    sudo systemctl enable --now docker.socket
    if id -nG "$USER" | grep -qw docker; then
        info "already in group: docker"
    else
        sudo usermod -aG docker "$USER"
        info "added to group: docker (re-login to apply)"
    fi

    log "system: audio"
    systemctl --user enable --now pipewire pipewire-pulse wireplumber

    log "system: ProtonVPN auto connect"
    install_file "$REPO_DIR/src/protonvpn.service" "$HOME/.config/systemd/user/protonvpn.service"
    systemctl --user daemon-reload
    systemctl --user enable protonvpn.service
}

step_shell() {
    log "shell: login shell"
    if [[ $(getent passwd "$USER" | cut -d: -f7) == /usr/bin/zsh ]]; then
        info "already zsh"
    else
        sudo usermod -s /usr/bin/zsh "$USER"
        info "changed to zsh (re-login to apply)"
    fi

    log "shell: zim"
    if [[ -d $HOME/.zim ]]; then
        info "already installed: zim"
    else
        curl -fsSL https://raw.githubusercontent.com/zimfw/install/master/install.zsh | zsh
    fi
    # zsh-autosuggestions / zsh-syntax-highlighting are in zim's default .zimrc
    append_once "$HOME/.zimrc" 'zmodule Aloxaf/fzf-tab'
    ZIM_HOME=${ZIM_HOME:-$HOME/.zim} zsh "${ZIM_HOME:-$HOME/.zim}/zimfw.zsh" install >/dev/null

    log "shell: starship"
    install_file "$REPO_DIR/src/starship.toml" "$HOME/.config/starship.toml"
    append_once "$HOME/.zshrc" 'eval "$(starship init zsh)"'

    log "shell: tty locale"
    if grep -q 'Linux console (tty) cannot render Japanese glyphs' "$HOME/.zshrc"; then
        info "already set: tty locale"
    else
        cat >>"$HOME/.zshrc" <<'EOF'

# Linux console (tty) cannot render Japanese glyphs: force English locale there
if [[ $TERM == linux ]]; then
  export LANG=en_US.UTF-8
  export LC_ALL=en_US.UTF-8
fi
EOF
        info "added: tty locale (~/.zshrc)"
    fi

    log "shell: kitty ($KITTY_SHELL)"
    local kitty_conf=$HOME/.config/kitty/kitty.conf
    if [[ -f $kitty_conf ]] && grep -qx "shell $KITTY_SHELL" "$kitty_conf"; then
        info "already set: shell $KITTY_SHELL"
    elif [[ -f $kitty_conf ]] && grep -q '^shell ' "$kitty_conf"; then
        cp -a "$kitty_conf" "$kitty_conf.bak.$STAMP"
        sed -i "s/^shell .*/shell $KITTY_SHELL/" "$kitty_conf"
        info "changed: shell $KITTY_SHELL"
    else
        append_once "$kitty_conf" "shell $KITTY_SHELL"
    fi
    # Ctrl+V paste: fish binds it itself, zsh does not
    if grep -qE '^map ctrl\+v[[:space:]]+paste_from_clipboard$' "$kitty_conf"; then
        info "already set: map ctrl+v paste_from_clipboard"
    else
        append_once "$kitty_conf" 'map ctrl+v    paste_from_clipboard'
    fi
    if pgrep -x kitty >/dev/null; then
        pkill -USR1 -x kitty
        info "reloaded: kitty config"
    fi

    log "shell: VS Code terminal font"
    python3 - "$HOME/.config/Code/User/settings.json" <<'EOF'
import json, os, sys
path = sys.argv[1]
key = "terminal.integrated.fontFamily"
value = "'JetBrainsMono Nerd Font Mono', 'Noto Sans Mono CJK JP', monospace"
settings = {}
if os.path.exists(path):
    try:
        settings = json.load(open(path))
    except json.JSONDecodeError:
        print(f"  ! {path} is not plain JSON (comments?), set {key} by hand", file=sys.stderr)
        sys.exit(0)
if settings.get(key) == value:
    print(f"    already set: {key}")
else:
    settings[key] = value
    os.makedirs(os.path.dirname(path), exist_ok=True)
    json.dump(settings, open(path, "w"), indent=4, ensure_ascii=False)
    print(f"    set: {key}")
EOF
}

step_fcitx5() {
    log "fcitx5: IME off by default, Henkan/Muhenkan on/off"
    # fcitx5 writes its config back on exit, so stop it before editing
    local was_running=0
    if pgrep -x fcitx5 >/dev/null; then
        was_running=1
        pkill -x fcitx5
        while pgrep -x fcitx5 >/dev/null; do sleep 0.2; done
    fi

    install_file "$REPO_DIR/src/fcitx5/profile" "$HOME/.config/fcitx5/profile"

    python3 - "$HOME/.config/fcitx5/config" <<'EOF'
import os, re, sys
path = sys.argv[1]
wanted = {
    "Hotkey/ActivateKeys": ["Hangul_Hanja", "Henkan_Mode"],
    "Hotkey/DeactivateKeys": ["Hangul_Romaja", "Muhenkan"],
}
lines = open(path).read().splitlines() if os.path.exists(path) else []
for section, keys in wanted.items():
    header = f"[{section}]"
    if header not in lines:
        lines += ["", header] + [f"{i}={k}" for i, k in enumerate(keys)]
        print(f"    added: {header}")
        continue
    start = lines.index(header) + 1
    end = start
    while end < len(lines) and not lines[end].startswith("["):
        end += 1
    entries = [l for l in lines[start:end] if re.match(r"^\d+=", l)]
    present = {l.split("=", 1)[1] for l in entries}
    missing = [k for k in keys if k not in present]
    insert_at = start + max((lines[start:end].index(e) + 1 for e in entries), default=0)
    for k in missing:
        lines.insert(insert_at, f"{len(entries)}={k}")
        entries.append(f"{len(entries)}={k}")
        insert_at += 1
        print(f"    added: {k} ({header})")
    if not missing:
        print(f"    already set: {header}")
os.makedirs(os.path.dirname(path), exist_ok=True)
open(path, "w").write("\n".join(lines) + "\n")
EOF

    if [[ $was_running == 1 ]] || in_hyprland; then
        setsid -f fcitx5 -d >/dev/null 2>&1
        info "restarted: fcitx5"
    fi
}

step_hyprland() {
    if [[ ! -f $HOME/.config/hypr/hyprland.lua ]]; then
        warn "dots-hyprland not installed (Hyprland/01_install.md), skipped"
        return
    fi

    log "hyprland: custom config (~/.config/hypr/custom)"
    local f
    for f in "$REPO_DIR"/Hyprland/src/custom/*.lua; do
        install_file "$f" "$HOME/.config/hypr/custom/$(basename "$f")"
    done

    log "hyprland: fingerprint on lock screen (PAM)"
    add_pam_fprintd /etc/pam.d/hyprlock

    log "hyprland: default file manager (nemo)"
    xdg-mime default nemo.desktop inode/directory
    info "inode/directory -> $(xdg-mime query default inode/directory)"
    # Same values on every run, so loading again changes nothing
    dconf load / <"$REPO_DIR/Hyprland/src/nemo/nemo.dconf"
    info "loaded: nemo preferences (Hyprland/src/nemo/nemo.dconf)"

    local qs=$HOME/.config/quickshell/ii
    if [[ -d $qs ]]; then
        log "hyprland: Quickshell bar (date, width, VPN, Night Light)"
        install_file "$REPO_DIR/Hyprland/src/VpnIndicator.qml" "$qs/modules/ii/bar/VpnIndicator.qml"
        install_file "$REPO_DIR/Hyprland/src/Hyprsunset.qml" "$qs/services/Hyprsunset.qml"
        python3 - "$qs/modules/ii/bar" <<'EOF'
import os, re, sys, shutil, time
bar = sys.argv[1]
stamp = time.strftime("%Y%m%d%H%M%S")

def patch(name, func):
    path = os.path.join(bar, name)
    src = open(path).read()
    out, msg = func(src)
    if out is None:
        print(f"  ! {name}: {msg}", file=sys.stderr)
    elif out == src:
        print(f"    already patched: {name} ({msg})")
    else:
        shutil.copy2(path, f"{path}.bak.{stamp}")
        open(path, "w").write(out)
        print(f"    patched: {name} ({msg})")

def clock(src):
    new = 'text: Qt.locale("ja_JP").toString(DateTime.clock.date, "MM/dd(ddd)")'
    if new in src:
        return src, "date"
    old = "text: DateTime.longDate"
    if src.count(old) != 1:
        return None, f"'{old}' not found"
    return src.replace(old, new), "date"

def popup(src):
    new = 'property string formattedDate: Qt.locale("ja_JP").toString(DateTime.clock.date, "yyyy/MM/dd (ddd)")'
    if new in src:
        return src, "date"
    out, n = re.subn(r"property string formattedDate: [^\n]*", new, src, count=1)
    return (out, "date") if n else (None, "formattedDate not found")

def content(src):
    # Fit the right center group (clock) to its content
    anchor = src.find("id: rightCenterGroup")
    if anchor < 0:
        return None, "rightCenterGroup not found"
    old = "implicitWidth: root.centerSideModuleWidth"
    new = "implicitWidth: rightCenterGroupContent.implicitWidth + 10 * 2"
    i = src.find(old, anchor)
    j = src.find("implicitHeight", anchor)
    if i >= 0 and i < j:
        src = src[:i] + new + src[i + len(old):]
    elif new not in src[anchor:j]:
        return None, "rightCenterGroup width not found"
    # VPN indicator before the weather widget
    if "VpnIndicator {}" not in src:
        m = re.search(r"^([ \t]*)// Weather$", src, re.M)
        if not m:
            return None, "// Weather not found"
        ind = m.group(1)
        block = (f"{ind}// VPN\n{ind}Loader {{\n{ind}    Layout.leftMargin: 4\n{ind}    active: true\n"
                 f"{ind}    sourceComponent: BarGroup {{\n{ind}        VpnIndicator {{}}\n{ind}    }}\n{ind}}}\n\n")
        src = src[:m.start()] + block + src[m.start():]
    return src, "width, VPN"

patch("ClockWidget.qml", clock)
patch("ClockWidgetPopup.qml", popup)
patch("BarContent.qml", content)
EOF
    else
        warn "Quickshell config not found, skipped: $qs"
    fi

    local ii_conf=$HOME/.config/illogical-impulse/config.json
    if [[ -f $ii_conf ]]; then
        log "hyprland: date format (lock screen etc.)"
        python3 - "$ii_conf" "$STAMP" <<'EOF'
import json, shutil, sys
path, stamp = sys.argv[1], sys.argv[2]
conf = json.load(open(path))
wanted = {"dateFormat": "yyyy/MM/dd (ddd)", "dateWithYearFormat": "yyyy/MM/dd", "shortDateFormat": "MM/dd"}
time_conf = conf.setdefault("time", {})
if all(time_conf.get(k) == v for k, v in wanted.items()):
    print("    already set: time.dateFormat")
else:
    shutil.copy2(path, f"{path}.bak.{stamp}")
    time_conf.update(wanted)
    json.dump(conf, open(path, "w"), indent=4, ensure_ascii=False)
    print("    set: time.dateFormat")
EOF
    fi

    if in_hyprland; then
        hyprctl reload >/dev/null
        info "reloaded: Hyprland"
    fi
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

if [[ $EUID -eq 0 ]]; then
    echo "Run as a normal user (sudo is used where needed)." >&2
    exit 1
fi

if [[ ${1:-} == --list ]]; then
    printf '%s\n' "${STEPS[@]}"
    exit 0
fi

selected=("$@")
[[ ${#selected[@]} -eq 0 ]] && selected=("${STEPS[@]}")

for s in "${selected[@]}"; do
    if ! declare -F "step_$s" >/dev/null; then
        echo "Unknown step: $s (see --list)" >&2
        exit 1
    fi
done

# Ask for the sudo password up front only when a step always needs it
if printf '%s\n' "${selected[@]}" | grep -qxE 'packages|system'; then
    sudo -v
fi
for s in "${selected[@]}"; do
    "step_$s"
done

log "done"
echo "    Log out and back in for group / shell changes to take effect."
