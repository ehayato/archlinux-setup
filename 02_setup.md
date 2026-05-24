# 細かいセットアップ（実行しなくても良い）
[基本的なセットアップ](01_base-install.md)が完了した後に行う細かいセットアップ。<br>
必須ではないが、システムの利便性や機能性を向上させるために行う。

## 時刻合わせ
WindowsとLinuxでRTCの扱いが異なるため、Linux側でRTCをローカルタイムとして扱うように設定する。<br>
`set-local-rtc 0`はUTC、`1`はローカルタイムを意味する。
```bash
sudo timedatectl set-local-rtc 1
timedatectl set-ntp true
```

## LightDMのインストール（なくても良い）
```bash
pacman -S lightdm lightdm-gtk-greeter
systemctl enable lightdm
```

## 電源ボタンの変更
電源ボタンをサスペンドに割り当てる。
`/etc/systemd/logind.conf`に以下を追加。
```
HandlePowerKey=suspend
```

## 画面の明るさ調整
```bash
yay -S brightnessctl
```
明るさを30%に設定したい場合。
```
brightnessctl s 30%
```

## 指紋センサーの設定
```bash
yay -S fprintd
systemctl enable fprintd
```
指紋登録をする。
```bash
fprintd-enroll
```
指紋認証を有効にする。
`/etc/pam.d/`配下の`system-auth`・`login`に以下を追加。
```
auth sufficient pam_fprintd.so
```

登録がおかしくなったら、`sudo fprintd-delete ""`で削除してから再度登録する。

# zsh + zim のインストール
```bash
sudo pacman -S zsh fzf
sudo usermod -s /usr/bin/zsh $USER
curl -fsSL https://raw.githubusercontent.com/zimfw/install/master/install.zsh | zsh
```

## zimモジュールの追加
`~/.zimrc`を編集して、以下のモジュールを追加する。
```
zmodule zsh-users/zsh-autosuggestions
zmodule zsh-users/zsh-syntax-highlighting
zmodule Aloxaf/fzf-tab
```

追記後、以下のコマンドでzimを再読み込みする。
```bash
zimfw reload
```

## kitty のシェル設定変更
`~/.config/kitty/kitty.conf` を編集。
```
# shell fish  ← コメントアウト
shell zsh
```

## starship の設定
```bash
echo 'eval "$(starship init zsh)"' >> ~/.zshrc
```

プリセットを適用する場合は以下のコマンドで選択できる。
```bash
starship preset --list
starship preset <プリセット名> -o ~/.config/starship.toml
```

カスタマイズ例(`~/.config/starship.toml`)は、[starship.toml](src/starship.toml)を参照。


## ソフトウェア
```bash
yay -S --needed \
    firefox zen-browser-bin google-chrome \
    docker docker-compose visual-studio-code-bin \
    proton-vpn-cli proton-pass \
    discord slack-desktop \
    vlc vlc-plugin-ffmpeg obs-studio \
    kdeconnect  
```
ユーザーをdockerグループに追加
```bash
sudo usermod -aG docker $USER
```

## 音が出ない場合
```bash
systemctl --user enable --now pipewire pipewire-pulse wireplumber
```

## ProtonVPNの自動接続
```bash
mkdir -p ~/.config/systemd/user
```
`~/.config/systemd/user/protonvpn.service`を作成し、[protonvpn.service](src/protonvpn.service)をコピーする。
有効化・起動・確認をする。
```bash
systemctl --user daemon-reload
systemctl --user enable --now protonvpn.service
systemctl --user status protonvpn.service
```
