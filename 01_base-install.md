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
Windowsのディスク管理からやっておくと楽。

```md
パーティション構成例（デュアルブート）

| パーティション | 用途               | FS    |
| -------------- | ------------------ | ----- |
| /dev/sda1      | EFI（Windows共用） | FAT32 |
| /dev/sda2      | Windows            | NTFS  |
| /dev/sda3      | Arch Linux /       | ext4  |
| /dev/sda4      | データ共有         | NTFS  |

⚠️ EFIパーティションは絶対にフォーマットしないこと！
```
(上記の構成に従ってパーティションを作成している前提で話を進める)

## パーティションの確認
```bash
lsblk
```

## フォーマット
```bash
mkfs.ext4 /dev/sda3
```

## マウント
インストール先を指定する。
```bash
mount /dev/sda3 /mnt
mkdir /mnt/boot
mount /dev/sda1 /mnt/boot
```

### 他のパーティションも必要に応じてマウントしておく
```bash
mkdir /mnt/data
mount /dev/sda4 /mnt/data
```

## サーバーのミラー指定
日本のミラーを取得し`/etc/pacman.d/mirrorlist`へ保存。適宜編集しておく。
```bash
reflector --sort rate --country jp --latest 10 --save /etc/pacman.d/mirrorlist
```

## ベースのインストール
`linux-firmware`は様々なハードウェアのファームウェアをまとめたパッケージ。<br>
`linux-firmware-*`で個別に必要なものだけをインストールすると、容量を節約できる。
```bash
pacstrap /mnt base base-devel linux linux-firmware sof-firmware bash-completion vim sudo ntfs-3g
```
|                 |                                                          |
| --------------- | -------------------------------------------------------- |
| base            | 必須。ArchLinuxのベース                                  |
| base-devel      | あると便利。開発ツール一式                               |
| linux           | 必須。標準カーネル。他に`linux-lts`と`linux-zen`がある。 |
| linux-firmware  | 必須。ファームウェア関連。                               |
| sof-firmware    | 必須。サウンド関連                                       |
| bash-completion | 便利。bash補完                                           |
| vim             | テキストエディタ                                         |
| sudo            | ユーザー権限の管理                                       |
| ntfs-3g         | NTFSファイルシステムのサポート                           |

#### `linux-firmware` について
|                        |                                                |
| ---------------------- | ---------------------------------------------- |
| linux-firmware-intel   | Intel 製品用 (内蔵GPU・無線LAN・Bluetooth等々) |
| linux-firmware-amdgpu  | AMD GPU                                        |
| linux-firmware-nvidia  | NVIDIA GPU                                     |
| linux-firmware-radeon  | ATI Radeon GPU                                 |
| linux-firmware-realtek | Realtek の無線LAN                              |

## マイクロコードとグラフィックドライバのインストール
`pacstrap`の段階で必要なものをインストールする。

#### マイクロコード
| | |
| - | - |
| intel-ucode | Intel CPUのマイクロコードアップデート |
| amd-ucode   | AMD CPUのマイクロコードアップデート   |

#### グラフィックドライバ
| | |
| - | - |
| mesa | OpenGL実装。Intel/AMD共通で必須 |
| vulkan-intel / vulkan-radeon | Vulkan対応。ゲームやエンコードに効く |
| intel-media-driver | IntelのVAAPI（ハードウェアデコード） |
| libva-mesa-driver | AMDのVAAPI（ハードウェアデコード） |

## fstabの作成
マウントしたパーティションを`/etc/fstab`に書き込む。
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
日本時間に設定。
```bash
ln -sf /usr/share/zoneinfo/Asia/Tokyo /etc/localtime
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

Windowsを認識させるため。<br>
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
gitとgoをインストール。
```bash
cd ~
pacman -S --needed git base-devel
```

```bash
git clone https://aur.archlinux.org/yay.git
cd yay && makepkg -si
cd ..
rm -r yay
```

おわり。

---

# 参考
山田 ハヤオさん
- [初心者向けのArchLinuxのインストールと初期設定（64bit環境にMBRでインストール）](https://qiita.com/Hayao0819/items/1ab6f2984878978d0c3c)

Azelさん
- [Arch Linux インストール](https://azelpg.gitlab.io/azsky2/note/archlinux/index.html)
