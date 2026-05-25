# Hyprland 追加セットアップ

[01_install.md](01_install.md) 完了後の追加設定。必要に応じて実施する。

---

## 指紋ログインの設定

[../../02_setup.md](../02_setup.md) で fprintd の設定を先に行う。

`/etc/pam.d/hyprlock` に追記する。

```
auth sufficient pam_fprintd.so
```

---

## 日本語環境

fcitx5 の自動起動を設定する。`~/.config/hypr/hyprland.conf` に追記する。

```
exec-once = fcitx5 -d
```

日本語キーボードの設定。`~/.config/hypr/hyprland/general.conf` の `input` セクションを編集する。

```
input {
    kb_layout = jp
    numlock_by_default = false
}
```

---

## ウィンドウルール

`~/.config/hypr/custom/rules.conf` に追記する。

```
# Discord・Slack をスペシャルワークスペースに配置
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

`~/.config/hypr/custom/keybinds.conf` に追記する。

```
# ProtonVPN 接続
bind = Super+Shift, V, exec, bash -c 'result=$(protonvpn connect | grep -oP "[\w ]+(?=\.)" | head -1); notify-send --app-name="ProtonVPN" "ProtonVPN" "$resultサーバーに接続しました。";'

# スペシャルワークスペースの切り替え
bind = Super+Shift, D, togglespecialworkspace, discord
bind = Super+Shift, S, togglespecialworkspace, slack
```

---

## バーの日時表記の変更

`yyyy/MM/dd (ddd)` 形式に変更する。対象ディレクトリは `~/.config/quickshell/ii/modules/ii/bar`。

### ClockWidget.qml

```diff
        StyledText {
            visible: root.showDate
            font.pixelSize: Appearance.font.pixelSize.small
            color: Appearance.colors.colOnLayer1
+           text: Qt.locale("ja_JP").toString(DateTime.clock.date, "MM/dd(ddd)")
        }
```

### ClockWidgetPopup.qml

```diff
StyledPopup {
    id: root
+   property string formattedDate: Qt.locale("ja_JP").toString(DateTime.clock.date, "yyyy/MM/dd (ddd)")
    property string formattedTime: DateTime.time

    # 以下省略
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

## ロック画面の日付表記の変更

`~/.config/illogical-impulse/config.json` の該当行を確認して変更する。

```bash
cat ~/.config/illogical-impulse/config.json | grep -i date
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