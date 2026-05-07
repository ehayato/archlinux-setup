# 細かいセットアップ（実行しなくても良い）
[Hyprlandのインストール](01_install.md)が完了した後に行う細かいセットアップ。

# 日本語環境
`fcitx5`の自動起動。
```bash
vim /home/hogehoge/.config/hypr/hyprland.conf
```
ここに以下を追加。
```
exec-once = fcitx5 -d
```

日本語キーボードの設定。
```bash
vim /home/hogehoge/.config/hypr/hyprland.conf
```
`input`セクションを編集。
```
input {
    kb_layout = jp
    numlock_by_default = false #NumLockをデフォルトでオフにする
}
```

# バーの日時を編集
`yyyy/MM/dd (ddd)`の形式に変更する。
```bash
cd /home/hogehoge/.config/quickshell/ii/modules/ii/bar
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