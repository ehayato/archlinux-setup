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

## LightDMのインストール
```bash
sudo pacman -S lightdm lightdm-gtk-greeter
sudo systemctl enable lightdm
```

## ソフトウェア
```bash
yay -S --needed \
    firefox zen-browser-bin google-chrome \
    docker docker-compose visual-studio-code-bin \
    protonvpn proton-pass \
    discord slack-desktop \
    vlc obs-studio \
    kdeconnect  
```
ユーザーをdockerグループに追加
```bash
sudo usermod -aG docker $USER
```