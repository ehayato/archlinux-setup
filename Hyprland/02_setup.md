# Hyprland 追加セットアップ

[01_install.md](01_install.md) 完了後の追加設定。必要に応じて実施する。

> Hyprland の設定は Lua 形式（`~/.config/hypr/hyprland.lua`）。自分の設定は `~/.config/hypr/custom/*.lua` に書く。`~/.config/hypr/hyprland/` 以下は dots-hyprland の更新で上書きされるので編集しない。
>
> `custom/` の設定ファイル一式は [src/custom/](src/custom/) にある。[../setup.sh](../setup.sh) を使うとまとめてコピーされる。

---

## 指紋ログインの設定

[../02_setup.md](../02_setup.md) で fprintd の設定を先に行う。

`/etc/pam.d/hyprlock` の最初の `auth` 行の前に追記する。

```
auth sufficient pam_fprintd.so
```

---

## 日本語環境

### fcitx5 の自動起動

`~/.config/hypr/custom/execs.lua` に追記する。

```lua
hl.on("hyprland.start", function ()
    hl.exec_cmd("fcitx5 -d")
end)
```

### 日本語キーボード

`~/.config/hypr/custom/general.lua` に追記する。`hyprland/general.lua` の `input` の設定のうち、ここに書いた項目だけが上書きされる。

```lua
hl.config({
    input = {
        kb_layout = "jp",
        numlock_by_default = false,
    },
})
```

### fcitx5 環境変数

`~/.config/hypr/custom/env.lua` に追記する。

```lua
hl.env("QT_IM_MODULE", "fcitx")
hl.env("XMODIFIERS", "@im=fcitx")
hl.env("SDL_IM_MODULE", "fcitx")
```

### 起動時に IME をオフにする

入力メソッドが Mozc だけだと、IME オフの状態でも Mozc が使われ、ターミナルやロック画面が日本語入力で始まってしまう。先頭に `keyboard-jp`（直接入力）を追加する。

> fcitx5 は終了時に設定を書き戻すため、fcitx5 を止めてから編集する。

```bash
pkill -x fcitx5
```

`~/.config/fcitx5/profile` を編集する（[../src/fcitx5/profile](../src/fcitx5/profile)）。

```ini
[Groups/0]
Name=Default
Default Layout=jp
DefaultIM=mozc

# 1番目: IME オフのときに使う
[Groups/0/Items/0]
Name=keyboard-jp
Layout=

# 2番目: IME オンのときに使う
[Groups/0/Items/1]
Name=mozc
Layout=

[GroupOrder]
0=Default
```

### 変換・無変換で IME をオン/オフする

`keyboard-jp` を追加すると、IME オフのときに Mozc にキーが届かなくなり、変換・無変換での切り替えが効かなくなる。fcitx5 側でキーを割り当てる。

`~/.config/fcitx5/config` の該当セクションに追記する。

```ini
[Hotkey/ActivateKeys]
0=Hangul_Hanja
1=Henkan_Mode

[Hotkey/DeactivateKeys]
0=Hangul_Romaja
1=Muhenkan
```

編集後に fcitx5 を起動する。

```bash
setsid -f fcitx5 -d
```

| キー | 動作 |
|---|---|
| 変換 | IME オン |
| 無変換 | IME オフ |
| 半角/全角、`Ctrl+Space` | 切り替え |

> `[Behavior]` の `ShareInputState=No`（デフォルト）のままにすると、IME の状態がウィンドウごとに保持され、新しいウィンドウは必ずオフで始まる。

---

## その他の環境変数

`~/.config/hypr/custom/env.lua` に追記する。

```lua
-- エディタ
hl.env("EDITOR", "vim")

-- カーソル
hl.env("XCURSOR_THEME", "Bibata-Modern-Classic")
hl.env("XCURSOR_SIZE", "24")

-- Wayland セッション情報（xdg-desktop-portal や各アプリに伝える）
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
```

`~/.config/hypr/custom/execs.lua` の `hl.on("hyprland.start", ...)` の中に追記する。

```lua
hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP HYPRLAND_INSTANCE_SIGNATURE DISPLAY")
hl.exec_cmd("systemctl --user start hyprland-session.target")
```

> ⚠️ 環境変数は `hyprctl reload` では反映されない。再ログインが必要。

---

## xdg-desktop-portal の設定

画面共有などのポータル機能を Hyprland に紐付ける設定。dots-hyprland が `~/.config/xdg-desktop-portal/hyprland-portals.conf` を配置するため、追加の作業は不要。

```ini
[preferred]
default = hyprland;gtk
org.freedesktop.impl.portal.FileChooser = kde
```

---

## デフォルトのファイルマネージャー（nemo）

`~/.config/hypr/custom/variables.lua` に追記する（`Super+E` で起動するアプリ）。

```lua
fileManager = "nemo"
```

フォルダを開くアプリも nemo にする。

```bash
xdg-mime default nemo.desktop inode/directory
```

### nemo の表示設定

nemo の設定は dconf に保存される。[src/nemo/nemo.dconf](src/nemo/nemo.dconf) を読み込む。

```bash
dconf load / < Hyprland/src/nemo/nemo.dconf
```

| 設定 | 値 | 内容 |
|---|---|---|
| `show-hidden-files` | `true` | 隠しファイル（`.` で始まるファイル）を表示 |
| `default-folder-viewer` | `'list-view'` | リスト表示をデフォルトにする |
| `inherit-folder-viewer` | `false` | 親フォルダの表示方法を引き継がない |
| `inherit-show-thumbnails` | `false` | 親フォルダのサムネイル表示設定を引き継がない |
| `date-format` | `'iso'` | 日付を `2026-11-04 09:00` 形式で表示 |
| `show-location-entry` | `true` | パスを文字で表示（パンくずリストではなく） |
| `show-*-toolbar` | `true` | ツールバーにボタンを表示（戻る、上へ、再読み込み、ホーム、コンピューター、新規フォルダ、端末で開く、サムネイル切り替え、2 画面切り替え） |
| `labels-beside-icons` | `true` | アイコン表示のとき、名前をアイコンの横に表示 |
| `side-pane-view` | `'tree'` | サイドバーをツリー表示にする |
| `start-with-sidebar` | `true` | サイドバーを表示して起動 |

### 「端末で開く」の端末

nemo の「端末で開く」は、デフォルトでは `gnome-terminal` を起動する。インストールしていないと何も起きないので、kitty に変更する（`nemo.dconf` にも含まれている）。

```bash
gsettings set org.cinnamon.desktop.default-applications.terminal exec kitty
```

> 設定を変更したら `dconf dump /org/nemo/` で確認し、`nemo.dconf` にも反映しておく。

---

## ウィンドウルール

`~/.config/hypr/custom/rules.lua` に追記する。

```lua
-- Discord・Slack をスペシャルワークスペースに配置
hl.window_rule({match = {class = "discord" }, workspace = "special:discord"})
hl.window_rule({match = {class = "slack" },   workspace = "special:slack"})

-- ピクチャーインピクチャーを右下に配置
hl.window_rule({match = {title = "ピクチャーインピクチャー" }, float = true})
hl.window_rule({match = {title = "ピクチャーインピクチャー" }, pin = true})
hl.window_rule({match = {title = "ピクチャーインピクチャー" }, size = {"(monitor_w*0.2)", "(monitor_h*0.2)"}})
hl.window_rule({match = {title = "ピクチャーインピクチャー" }, move = {"(monitor_w*0.75)", "(monitor_h*0.75)"}})

-- ダイアログの自動フロート
hl.window_rule({match = {class = "org.kde.ark" }, float = true})

-- ピン留めされたウィンドウの枠線（桜色）
hl.window_rule({match = {pin = 1 }, border_color = "rgb(FFB7C5)"})
hl.window_rule({match = {pin = 1 }, border_size = 2})

-- Zoom をフロートにし、最大化・全画面を無効化
hl.window_rule({match = {class = "^(zoom)$" }, float = true})
hl.window_rule({match = {class = "^(zoom)$" }, suppress_event = "maximize fullscreen"})
```

---

## キーバインド

`~/.config/hypr/custom/keybinds.lua` に追記する。主な部分のみ抜粋。全体は [src/custom/keybinds.lua](src/custom/keybinds.lua) を参照。

```lua
-- ブラウザ（デフォルトのサイドバー表示を置き換え）
hl.unbind("SUPER + B")
hl.bind("SUPER + B", hl.dsp.exec_cmd("~/.config/hypr/hyprland/scripts/launch_first_available.sh \"zen-browser\" \"firefox\" \"google-chrome-stable\""), { description = "Browser" })

-- ProtonVPN 接続
hl.bind("SUPER + SHIFT + V", hl.dsp.exec_cmd([[bash -c 'result=$(protonvpn connect | grep -oP "[\w ]+(?=\.)" | head -1); notify-send --app-name="ProtonVPN" "ProtonVPN" "$resultサーバーに接続しました。";']]), { description = "ProtonVPN connect" })

-- スペシャルワークスペースの切り替え
hl.bind("SUPER + SHIFT + D", hl.dsp.workspace.toggle_special("discord"), { description = "Toggle Discord workspace" })
hl.unbind("SUPER + SHIFT + S") -- デフォルトの範囲スクリーンショットは Shift+Print に移動
hl.bind("SUPER + SHIFT + S", hl.dsp.workspace.toggle_special("slack"), { description = "Toggle Slack workspace" })

-- 範囲スクリーンショット
hl.bind("SHIFT + Print", hl.dsp.global("quickshell:regionScreenshot"), { description = "Utilities: Screen snip" })

-- フローティングトグル
hl.bind("SUPER + Space", hl.dsp.window.float({ action = "toggle" }), { description = "Toggle floating for the focused window" })
```

| キー | 動作 |
|---|---|
| `Super+B` | ブラウザ |
| `Super+E` | ファイルマネージャー（nemo） |
| `Super+Shift+V` | ProtonVPN 接続 |
| `Super+Shift+D` | Discord ワークスペース |
| `Super+Shift+S` | Slack ワークスペース |
| `Shift+Print` | 範囲スクリーンショット |
| `Super+Space` | フローティング切り替え |

---

## バーの日時表記の変更

`yyyy/MM/dd (ddd)` 形式に変更する。対象ディレクトリは `~/.config/quickshell/ii/modules/ii/bar`。

### ClockWidget.qml

```diff
        StyledText {
            visible: root.showDate
            font.pixelSize: Appearance.font.pixelSize.small
            color: Appearance.colors.colOnLayer1
-           text: DateTime.longDate
+           text: Qt.locale("ja_JP").toString(DateTime.clock.date, "MM/dd(ddd)")
        }
```

### ClockWidgetPopup.qml

```diff
StyledPopup {
    id: root
-   property string formattedDate: Qt.locale().toString(DateTime.clock.date, "dddd, MMMM dd, yyyy")
+   property string formattedDate: Qt.locale("ja_JP").toString(DateTime.clock.date, "yyyy/MM/dd (ddd)")
    property string formattedTime: DateTime.time
```

---

## バーの日時幅の調整

`~/.config/quickshell/ii/modules/ii/bar/BarContent.qml` を編集する。

```diff
MouseArea {
  id: rightCenterGroup
  anchors.verticalCenter: parent.verticalCenter
- implicitWidth: root.centerSideModuleWidth
+ implicitWidth: rightCenterGroupContent.implicitWidth + 10 * 2
  implicitHeight: rightCenterGroupContent.implicitHeight
```

---

## Night Light の無効化

`~/.config/quickshell/ii/services/Hyprsunset.qml` を [src/Hyprsunset.qml](src/Hyprsunset.qml) の内容に差し替える。

---

## VPN インジケーターの設置

`~/.config/quickshell/ii/modules/ii/bar` に [src/VpnIndicator.qml](src/VpnIndicator.qml) を配置する。

`BarContent.qml` に追記する。

```diff
+ // VPN
+ Loader {
+     Layout.leftMargin: 4
+     active: true
+     sourceComponent: BarGroup {
+         VpnIndicator {}
+     }
+ }

// Weather
Loader {
```

---

## ロック画面などの日付表記の変更

`~/.config/illogical-impulse/config.json` の `time` を編集する。

```json
"time": {
    "dateFormat": "yyyy/MM/dd (ddd)",
    "dateWithYearFormat": "yyyy/MM/dd",
    "shortDateFormat": "MM/dd"
}
```

---

## Power Profiles の使用（任意）

```bash
yay -S power-profiles-daemon
```

---

## 音が出ない場合

```bash
systemctl --user enable --now pipewire pipewire-pulse wireplumber
```
