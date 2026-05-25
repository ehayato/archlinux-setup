# 追加セットアップ

[01_base-install.md](01_base-install.md) 完了後の追加設定。必要に応じて実施する。

---

## 時刻合わせ（Windows デュアルブート）

Windows と Linux では RTC の扱いが異なるため、Linux 側をローカルタイムに合わせる。

```bash
sudo timedatectl set-local-rtc 1
timedatectl set-ntp true
```

---

## ディスプレイマネージャー（任意）

```bash
pacman -S lightdm lightdm-gtk-greeter
systemctl enable lightdm
```

---

## 電源ボタンの割り当て変更

電源ボタンをサスペンドに割り当てる。`/etc/systemd/logind.conf` に追記する。

```
HandlePowerKey=suspend
```

---

## 画面の明るさ調整

```bash
yay -S brightnessctl

# 明るさを 30% に設定する例
brightnessctl s 30%
```

---

## 指紋センサーの設定

```bash
yay -S fprintd
systemctl enable fprintd

# 指紋登録
fprintd-enroll
```

`/etc/pam.d/system-auth` と `/etc/pam.d/login` に追記する。

```
auth sufficient pam_fprintd.so
```

> 登録をやり直す場合は `sudo fprintd-delete ""` で削除してから再登録する。

---

## zsh + zim のインストール

```bash
sudo pacman -S zsh fzf
sudo usermod -s /usr/bin/zsh $USER
curl -fsSL https://raw.githubusercontent.com/zimfw/install/master/install.zsh | zsh
```

### zim モジュールの追加

`~/.zimrc` に以下を追記する。

```
zmodule zsh-users/zsh-autosuggestions
zmodule zsh-users/zsh-syntax-highlighting
zmodule Aloxaf/fzf-tab
```

```bash
zimfw install
```

### kitty のシェル設定変更

`~/.config/kitty/kitty.conf` を編集する。

```
shell zsh
```

### starship の設定

```bash
echo 'eval "$(starship init zsh)"' >> ~/.zshrc
```

プリセット一覧の確認と適用は以下の通り。

```bash
starship preset --list
starship preset <プリセット名> -o ~/.config/starship.toml
```

カスタマイズ例は [src/starship.toml](src/starship.toml) を参照。

---

## ソフトウェア

```bash
yay -S --needed \
    firefox zen-browser-bin google-chrome \
    docker docker-compose visual-studio-code-bin \
    proton-vpn-cli proton-pass \
    discord slack-desktop \
    vlc obs-studio
```

### Docker グループへの追加

```bash
sudo usermod -aG docker $USER
```

---

## 音が出ない場合

```bash
systemctl --user enable --now pipewire pipewire-pulse wireplumber
```

---

## ProtonVPN の自動接続

```bash
mkdir -p ~/.config/systemd/user
```

`~/.config/systemd/user/protonvpn.service` を作成し、[src/protonvpn.service](src/protonvpn.service) をコピーする。

```bash
systemctl --user daemon-reload
systemctl --user enable --now protonvpn.service
systemctl --user status protonvpn.service
```