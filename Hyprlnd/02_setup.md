# 細かいセットアップ（実行しなくても良い）
[Hyprlandのインストール](01_install.md)が完了した後に行う細かいセットアップ。

# 指紋ログインの設定
ベースの[../02_setup.md](../02_setup.md)で指紋センサーの設定を行う。
`/etc/pam.d/hyprlock`に以下を追加。
```
auth sufficient pam_fprintd.so
```

# 日本語環境
`fcitx5`の自動起動。
```bash
vim ~/.config/hypr/hyprland.conf
```
ここに以下を追加。
```
exec-once = fcitx5 -d
```

日本語キーボードの設定。
```bash
~/.config/hypr/hyprland/general.conf
```
`input`セクションを編集。
```
input {
    kb_layout = jp
    numlock_by_default = false #NumLockをデフォルトでオフにする
}
```

# ウィンドウルール
`~/.config/hypr/custom/rules.conf`
```
# DiscordやSlackをスペシャルワークスペースに配置
windowrule = match:class discord, workspace special:discord
windowrule = match:class slack, workspace special:slack

# ピクチャーインピクチャーを右下に配置
windowrule = match:title ピクチャーインピクチャー, float on
windowrule = match:title ピクチャーインピクチャー, pin on
windowrule = match:title ピクチャーインピクチャー, size 20% 20%
windowrule = match:title ピクチャーインピクチャー, move 1250 800

# ダイアログの自動フロート
windowrule = match:class org.kde.ark, float on

# ピン留めされたウィンドウの枠線（桜色）
windowrule = match:pin 1, border_color rgb(FFB7C5)
windowrule = match:pin 1, border_size 2
```

`~/.config/hypr/custom/keybinds.conf`
```
# ProtonVPN接続
bind = Super+Shift, V, exec, bash -c 'result=$(protonvpn connect | grep -oP "[\w ]+(?=\.)" | head -1); notify-send --app-name="ProtonVPN" "ProtonVPN" "$resultサーバーに接続しました。";' # ProtonVPN connect

# スペシャルワークスペースの切り替え
bind = Super+Shift, D, togglespecialworkspace, discord # Toggle Discord workspace
bind = Super+Shift, S, togglespecialworkspace, slack # Toggle Slack workspace
```

# バーの日時を編集
`yyyy/MM/dd (ddd)`の形式に変更する。
```bash
~/.config/quickshell/ii/modules/ii/bar
```
以下のように編集する。

`ClockWidget.qml`
```diff
Item {
    ...省略...
    RowLayout {
        ...
        StyledText {
            ...
        }

        StyledText {
            ...
        }

        StyledText {
            visible: root.showDate
            font.pixelSize: Appearance.font.pixelSize.small
            color: Appearance.colors.colOnLayer1
+           text: Qt.locale("ja_JP").toString(DateTime.clock.date, "MM/dd(ddd)")
        }
```

`ClockWidgetPopup.qml`
```diff
StyledPopup {
    id: root
+   property string formattedDate: Qt.locale("ja_JP").toString(DateTime.clock.date, "yyyy/MM/dd (ddd)")
    property string formattedTime: DateTime.time
    property string formattedUptime: DateTime.uptime
    property string todosSection: getUpcomingTodos()

    ...省略...
}
```

# バーの日時幅を調整したい場合
```
~/.config/quickshell/ii/modules/ii/bar/BarContent.qml
```
```diff
MouseArea {
  id: rightCenterGroup
  anchors.verticalCenter: parent.verticalCenter
- implicitWidth: root.centerSideModuleWidth
+ implicitWidth: rightCenterGroupContent.implicitWidth + 10 * 2 // 左右に10pxのpaddingを追加
  implicitHeight: rightCenterGroupContent.implicitHeight

# Night Lightの無効化
勝手に起動されてウザいので無効化する。
```bash
~/.config/quickshell/ii/services/Hyprsunset.qml
```
これを[Hyprsunset.qml](src/Hyprsunset.qml)のように編集する。

# VPNインジケーターの設置
ProtnVPNのインジケーターを設置する。
```bash
~/.config/quickshell/ii/modules/ii/bar
```
ここに[VpnIndicator.qml](src/VpnIndicator.qml)を作る。

`BarContent.qml`の下の方に追記する。
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
    ...省略...
}
```

# PowerProfileを使いたい場合
```bash
yay -S power-profiles-daemon
```

# 音が出ない場合
```bash
systemctl --user enable --now pipewire pipewire-pulse wireplumber
```