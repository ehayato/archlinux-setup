# 目指すところ
- Windowsとのデュアルブート

# インストール
USBメモリからArchLinuxを起動

## キーボードレイアウトの変更
```bash
loadkeys jp106
```

## インターネット接続
```bash 
iwctl station {Device} connect {SSID} 
```

## 時刻合わせ
```bash
timedatectl set-ntp true
```

## パーティショニング
Windowsのディスク管理からやっておく。

パーティションの確認
```bash
lsblk
```

## フォーマット
```bash
mkfs.ext4 /dev/sdax
```

## マウント
インストール先を指定する。
```bash
mount /dev/sda2 /mnt
mkdir /mnt/boot
mount /dev/sda1 /mnt/boot
```

## サーバーのミラー指定
日本のミラーを取得し`/etc/pacman.d/mirrorlist`へ保存。適宜編集しておく。
```bash
reflector --sort rate --country jp --latest 10 --save /etc/pacman.d/mirrorlist
```

## ベースのインストール
```bash
pacstrap /mnt base base-devel linux linux-firmware sof-firmware bash-completion vim nano sudo
```
|                 |                                                          |
| --------------- | -------------------------------------------------------- |
| base            | 必須。ArchLinuxのベース                                  |
| base-devel      | あると便利。開発ツール一式                               |
| linux           | 必須。標準カーネル。他に`linux-lts`と`linux-zen`がある。 |
| linux-firmware  | 必須。ファームウェア関連                                 |
| sof-firmware    | 必須。サウンド関連                                       |
| bash-completion | 便利。bash補完                                           |

### `linux-firmware` について
|                        |                                                |
| ---------------------- | ---------------------------------------------- |
| linux-firmware-intel   | Intel 製品用 (内蔵GPU・無線LAN・Bluetooth等々) |
| linux-firmware-amdgpu  | AMD GPU                                        |
| linux-firmware-nvidia  | NVIDIA GPU                                     |
| linux-firmware-radeon  | ATI Radeon GPU                                 |
| linux-firmware-realtek | Realtek の無線LAN                              |

## fstabの作成
```bash
genfstab -U /mnt >> /mnt/etc/fstab
```

---

# システムの設定
インストールしたシステムに入る。
```bash
arch-chroot /mnt
```

## ロケール設定
```
vim /etc/locale.gen
```
`en_US.UTF-8 UTF-8`と`ja_JP.UTF-8 UTF-8`をアンコメント。

続けて以下を実行。
```bash
locale-gen
echo LANG=en_US.UTF-8 > /etc/locale.conf
```

## タイムゾーン設定
表示に従って設定。
```bash
tzselect
```

## キーマップ設定
```bash
echo KEYMAP=jp106 > /etc/vconsole.conf
```

## ホスト名の設定
好きなホスト名を設定。
```bash
echo hogehoge > /etc/hostname
```

## rootのパスワード設定
```bash
passwd root
```

## 一般ユーザー追加
```bash
useradd -m -G wheel hogehoge
passwd hogehoge
```

## sudoの設定
```
visudo
```
`%wheel ALL=(ALL:ALL) ALL`をアンコメント。

## 必要なものをインストール
```bash
pacman -S grub efibootmgr os-prober networkmanager
```

## Grubのファイルをインストール
`--bootloader-id`は作成するブートローダーの名前。<br>
指定した名前のディレクトリが`/boot/EFI`に作られる。
```bash
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=hogehoge
```

### Grubの設定変更
```bash
vim /etc/default/grub
```
コメントアウト：`GRUB_CMDLINE_LINUX_DEFAULT="なんたら"`<br>
アンコメント：`GRUB_DISABLE_OS_PROBER=false`

保存したら、以下を実行。
```bash
grub-mkconfig -o /boot/grub/grub.cfg
```

---

インストール作業終了

---

# システムから抜けて再起動
```bash
exit
umount -R /mnt
reboot
```

# 再起動後
## インターネットに接続
```bash
systemctl enable NetworkManager
systemctl start NetworkManager
```
Wi-Fi接続
```bash
nmcli device wifi connect {SSID} password {Password}
```
or
```bash
nmtui
```

## パッケージ更新
```bash
pacman -Syu
```

## yayのインストール
```bash
cd ~
pacman -S git
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si
cd ..
rm -r yay
```

おわり。

# 参考
山田 ハヤオさん
- [初心者向けのArchLinuxのインストールと初期設定（64bit環境にMBRでインストール）](https://qiita.com/Hayao0819/items/1ab6f2984878978d0c3c)

Azelさん
- [Arch Linux インストール](https://azelpg.gitlab.io/azsky2/note/archlinux/index.html)
