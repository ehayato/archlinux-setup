# Arch Linux インストール手順

Windows とのデュアルブート構成を前提とした手順。

---

## 事前準備

Windows のディスク管理から、Arch Linux 用のパーティションを切り出しておくと作業が楽。

### パーティション構成例（デュアルブート）

| パーティション | 用途                | FS    |
| -------------- | ------------------- | ----- |
| /dev/sda1      | EFI（Windows 共用） | FAT32 |
| /dev/sda2      | Windows             | NTFS  |
| /dev/sda3      | Arch Linux `/`      | ext4  |
| /dev/sda4      | データ共有          | NTFS  |

> ⚠️ EFI パーティションは絶対にフォーマットしないこと。

---

## 1. 起動・初期設定

USB メモリから Arch Linux を起動する。

```bash
# キーボードレイアウトの変更
loadkeys jp106

# インターネット接続（Wi-Fi）
iwctl station {Device} connect {SSID}

# 時刻合わせ
timedatectl set-ntp true
```

---

## 2. パーティショニング

```bash
lsblk  # ディスク名を確認
gdisk /dev/sda
```

gdisk の操作手順：

| コマンド | 説明                       |
| -------- | -------------------------- |
| `o`      | GPT テーブルを新規作成     |
| `n`      | パーティションを追加       |
| `t`      | パーティションタイプを変更 |
| `w`      | 変更を書き込んで終了       |

### パーティションタイプコード

| 用途  | コード |
| ----- | ------ |
| EFI   | `ef00` |
| Linux | `8300` |

### シングルブートの場合

```
パーティション 1: +512M、タイプ ef00（EFI）
パーティション 2: 残り全部、タイプ 8300（/）
```

### デュアルブートの場合

既存の EFI パーティションをそのまま使用する。新規に Linux 用パーティションのみ作成する。

---

## 3. フォーマットとマウント

```bash
# シングルブートの場合は EFI もフォーマット
mkfs.fat -F32 /dev/sda1

# ルートパーティション
mkfs.ext4 /dev/sda3

# マウント
mount /dev/sda3 /mnt
mkdir /mnt/boot
mount /dev/sda1 /mnt/boot

# データパーティションが必要な場合
mkdir /mnt/data
mount /dev/sda4 /mnt/data
```

---

## 4. ミラーの設定

日本のミラーを取得して `/etc/pacman.d/mirrorlist` に保存する。

```bash
reflector --sort rate --country jp --latest 10 --save /etc/pacman.d/mirrorlist
```

---

## 5. ベースシステムのインストール

```bash
pacstrap /mnt base base-devel linux linux-firmware sof-firmware bash-completion vim sudo ntfs-3g
```

| パッケージ      | 説明                                           |
| --------------- | ---------------------------------------------- |
| base            | Arch Linux のベース                            |
| base-devel      | 開発ツール一式                                 |
| linux           | 標準カーネル（他に `linux-lts` / `linux-zen`） |
| linux-firmware  | ファームウェア関連                             |
| sof-firmware    | サウンド関連                                   |
| bash-completion | bash 補完                                      |
| vim             | テキストエディタ                               |
| sudo            | ユーザー権限管理                               |
| ntfs-3g         | NTFS サポート                                  |

### マイクロコード

CPU メーカーを確認してから対応するパッケージを `pacstrap` に追加する。

```bash
# CPU の確認
grep -m1 "vendor_id" /proc/cpuinfo
# GenuineIntel → Intel / AuthenticAMD → AMD
```

| パッケージ  | 対象      |
| ----------- | --------- |
| intel-ucode | Intel CPU |
| amd-ucode   | AMD CPU   |

### グラフィックドライバ

GPU を確認してから対応するパッケージを選択する。

```bash
# GPU の確認
lspci | grep -E "VGA|3D"
```

| 構成       | パッケージ                                 |
| ---------- | ------------------------------------------ |
| Intel 内蔵 | `mesa` `vulkan-intel` `intel-media-driver` |
| AMD        | `mesa` `vulkan-radeon` `libva-mesa-driver` |
| NVIDIA     | `nvidia` `nvidia-utils`                    |

- `mesa` : OpenGL 実装。Intel / AMD で必須
- `vulkan-*` : Vulkan 対応。ゲームやエンコードに効く
- `intel-media-driver` / `libva-mesa-driver` : VAAPI（ハードウェアデコード）
- `nvidia-utils` : NVIDIA ユーティリティ・Vulkan サポート

### pacstrap コマンド例（Intel CPU + Intel 内蔵 GPU の場合）

```bash
pacstrap /mnt intel-ucode mesa vulkan-intel intel-media-driver
```

---

## 6. fstab の生成

```bash
genfstab -U /mnt >> /mnt/etc/fstab
```

---

## 7. システム設定

```bash
arch-chroot /mnt
```

### ロケール

```bash
# /etc/locale.gen を開いて以下の行をアンコメント
# en_US.UTF-8 UTF-8
# ja_JP.UTF-8 UTF-8
vim /etc/locale.gen

locale-gen
echo LANG=en_US.UTF-8 > /etc/locale.conf
```

### タイムゾーン・キーマップ・ホスト名

```bash
ln -sf /usr/share/zoneinfo/Asia/Tokyo /etc/localtime
echo KEYMAP=jp106 > /etc/vconsole.conf
echo hogehoge > /etc/hostname
```

### ユーザー設定

```bash
passwd root

useradd -m -G wheel hogehoge
passwd hogehoge

# visudo で %wheel ALL=(ALL:ALL) ALL をアンコメント
visudo
```

---

## 8. Swap の設定

ハイバネートを使用する場合は RAM 容量以上のサイズで作成する。

```bash
mkswap -U clear --size 16G --file /swapfile
swapon /swapfile
```

`/etc/fstab` に追記する。

```
/swapfile none swap defaults 0 0
```

---

## 9. ハイバネートの設定

`/etc/mkinitcpio.conf` の `HOOKS` に `resume` を追加する。

```
HOOKS=(base udev autodetect modconf block filesystems keyboard resume fsck)
```

> `resume` は `filesystems` の **後** に配置すること。

```bash
mkinitcpio -P
```

`/etc/systemd/sleep.conf` に追記する。

```
AllowHibernation=yes
HibernateDelaySec=3600
```

---

## 10. ブートローダーの設定

```bash
pacman -S grub efibootmgr os-prober

grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=hogehoge
```

### resume パラメータの追加

```bash
UUID=$(findmnt -no UUID -T /swapfile)
OFFSET=$(sudo filefrag -v /swapfile | awk 'NR==4{print $4}' | cut -d. -f1)

sed -i "s/GRUB_CMDLINE_LINUX=\"\"/GRUB_CMDLINE_LINUX=\"resume=UUID=$UUID resume_offset=$OFFSET\"/" /etc/default/grub
```

`/etc/default/grub` を編集する。

- `GRUB_CMDLINE_LINUX_DEFAULT="..."` をコメントアウト（起動ログを表示するため）
- `GRUB_DISABLE_OS_PROBER=false` をアンコメント（Windows を認識させるため）

```bash
grub-mkconfig -o /boot/grub/grub.cfg
```

---

## 11. 再起動

```bash
exit
umount -R /mnt
reboot
```

---

## 12. 再起動後の設定

```bash
# NetworkManager の有効化
systemctl enable NetworkManager
systemctl start NetworkManager

# Wi-Fi 接続
nmtui

# パッケージ更新
pacman -Syu
```

### yay のインストール

```bash
pacman -S --needed git base-devel

git clone https://aur.archlinux.org/yay.git
cd yay && makepkg -si
cd .. && rm -r yay
```

---

## 13. 日本語環境

```bash
# フォント
pacman -S noto-fonts-cjk noto-fonts-emoji ttf-jetbrains-mono-nerd

# 日本語入力
pacman -S fcitx5 fcitx5-mozc fcitx5-gtk fcitx5-qt fcitx5-configtool
```

`/etc/environment` に追記する。

```
XMODIFIERS=@im=fcitx
```

---

## 次のステップ

追加のセットアップは [02_setup.md](02_setup.md) を参照。