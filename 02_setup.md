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

## 電源ボタンの変更
電源ボタンをサスペンドに割り当てる。
```bash
vim /etc/systemd/logind.conf
```
以下を追加。
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
sudo systemctl enable fprintd
```

指紋登録をする。
```bash
fprintd-enroll
```

指紋認証を有効にする。
```bash
sudo vim /etc/pam.d/system-auth
```
以下を追加。
```
auth sufficient pam_fprintd.so
```


## ソフトウェア
```bash
yay -S --needed \
    firefox zen-browser-bin google-chrome \
    docker docker-compose visual-studio-code-bin \
    protonvpn-cli proton-pass \
    discord slack-desktop \
    vlc obs-studio \
    kdeconnect  
```
ユーザーをdockerグループに追加
```bash
sudo usermod -aG docker $USER
```