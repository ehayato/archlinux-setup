# archlinux-setup (自分用)

Arch Linux のインストールから環境構築までの手順をまとめたリポジトリ。

---

## ファイル構成

```
archlinux-setup/
├── 01_base-install.md   # Arch Linux ベースインストール手順
├── 02_setup.md          # 追加セットアップ
├── setup.sh             # 02_setup.md と Hyprland/02_setup.md を一括適用するスクリプト
├── Hyprland/
│   ├── 01_install.md    # Hyprland インストール手順
│   ├── 02_setup.md      # Hyprland 追加セットアップ
│   └── src/             # 設定ファイル（custom/*.lua、Quickshell の QML）
└── src/                 # 設定ファイル（starship、fcitx5、systemd など）
```

---

## クイックスタート

1. [01_base-install.md](01_base-install.md) に従って Arch Linux をインストール
2. Hyprland を使う場合は [Hyprland/01_install.md](Hyprland/01_install.md) で dots-hyprland をインストール
3. `setup.sh` で追加設定を一括適用

```bash
git clone https://github.com/ehayato/archlinux-setup.git
cd archlinux-setup
./setup.sh
```

---

## setup.sh

[02_setup.md](02_setup.md) と [Hyprland/02_setup.md](Hyprland/02_setup.md) の設定をまとめて適用する。一般ユーザーで実行する（必要なところだけ sudo を使う）。

- 何度実行しても同じ結果になる。適用済みの項目は飛ばす
- 既存のファイルを書き換えるときは `<ファイル名>.bak.<日時>` にバックアップを作る
- dots-hyprland が上書きする設定（kitty など）があるため、dots-hyprland のインストール・更新の **後** に実行する

### ステップ

| ステップ | 内容 |
|---|---|
| `packages` | yay、マイクロコード、アプリのインストール |
| `system` | RTC、電源ボタン・蓋の動作、指紋認証（PAM）、Docker、PipeWire、ProtonVPN |
| `shell` | zsh・zim・starship、tty の文字化け対策、kitty のシェル、VS Code ターミナルのフォント |
| `fcitx5` | 起動時に IME オフ、変換・無変換で IME オン/オフ |
| `hyprland` | `custom/*.lua`、ロック画面の指紋認証、nemo（デフォルト化・表示設定）、Quickshell のバー、日付表記 |

```bash
./setup.sh                  # 全ステップを実行
./setup.sh shell fcitx5     # 指定したステップだけ実行
./setup.sh --list           # ステップの一覧
```

### オプション（環境変数）

| 変数 | デフォルト | 内容 |
|---|---|---|
| `DUAL_BOOT` | `1` | `0` にすると RTC をローカルタイムにしない（Windows とのデュアルブートでない場合） |
| `KITTY_SHELL` | `zsh` | kitty で起動するシェル |

```bash
DUAL_BOOT=0 ./setup.sh
```

### スクリプトに含まれないもの

以下は手動で行う。

- 指紋の登録（`fprintd-enroll`）
- ProtonVPN へのログイン
- ディスプレイマネージャー（任意）
