# 追加セットアップ

[01_base-install.md](01_base-install.md) 完了後の追加設定。必要に応じて実施する。

---

## 時刻合わせ（Windows デュアルブート）

Windows と Linux では RTC の扱いが異なるため、Linux 側をローカルタイムに合わせる。

```bash
sudo timedatectl set-local-rtc 1
timedatectl set-ntp true
```

---

## ディスプレイマネージャー（任意）

```bash
pacman -S lightdm lightdm-gtk-greeter
systemctl enable lightdm
```

---

## ハイバネート：蓋を閉じたときの動作

`01_base-install.md` の手順でハイバネートを有効化した場合、蓋を閉じたときの動作を環境ごとに設定する。

### Hyprland・CLI の場合

`/etc/systemd/logind.conf` を編集する。

```
HandleLidSwitch=suspend-then-hibernate
HandleLidSwitchExternalPower=suspend-then-hibernate
```

変更後はlogindを再起動する。

```bash
systemctl restart systemd-logind
```

### GNOMEやKDEの場合

`logind.conf` の設定はDEが上書きするため、DE側の電源管理設定から「蓋を閉じたとき」の動作を `サスペンド後にハイバネート` に変更する。

---

## 電源ボタンの割り当て変更

電源ボタンをサスペンドに割り当てる。`/etc/systemd/logind.conf` に追記する。

```
HandlePowerKey=suspend
```

---

## 画面の明るさ調整

```bash
yay -S brightnessctl

# 明るさを 30% に設定する例
brightnessctl s 30%
```

---

## 指紋センサーの設定

```bash
yay -S fprintd
systemctl enable fprintd

# 指紋登録
fprintd-enroll
```

`/etc/pam.d/system-auth` と `/etc/pam.d/login` に追記する。

```
auth sufficient pam_fprintd.so
```

> 登録をやり直す場合は `sudo fprintd-delete ""` で削除してから再登録する。

---

## zsh + zim のインストール

```bash
sudo pacman -S zsh fzf
sudo usermod -s /usr/bin/zsh $USER
curl -fsSL https://raw.githubusercontent.com/zimfw/install/master/install.zsh | zsh
```

### zim モジュールの追加

`~/.zimrc` に以下を追記する。

```
zmodule zsh-users/zsh-autosuggestions
zmodule zsh-users/zsh-syntax-highlighting
zmodule Aloxaf/fzf-tab
```

```bash
zimfw install
```

### kitty のシェル設定変更

`~/.config/kitty/kitty.conf` を編集する。

```
shell zsh
```

### starship の設定

```bash
echo 'eval "$(starship init zsh)"' >> ~/.zshrc
```

プリセット一覧の確認と適用は以下の通り。

```bash
starship preset --list
starship preset <プリセット名> -o ~/.config/starship.toml
```

### starship のカスタマイズ

プリセットを使わずに自作の設定を使う場合は、[src/starship.toml](src/starship.toml) を `~/.config/starship.toml` にコピーする。

```bash
cp src/starship.toml ~/.config/starship.toml
```

保存すると次のプロンプト表示から反映される（シェルの再起動は不要）。

#### 表示イメージ

git リポジトリ内で 3 秒かかるコマンドを実行した後の表示。

```
user@host:~/dir main 3s
> 
```

| 表示 | 内容 | 色 | 設定するセクション |
|---|---|---|---|
| `user` | ユーザー名 | 太字の緑（root のときは赤） | `[username]` |
| `@host` | ホスト名 | 太字の緑 | `[hostname]` |
| `:~/dir` | カレントディレクトリ | 太字の青 | `[directory]` |
| `main` | git ブランチ（git リポジトリ内のみ） | 太字の紫 | `[git_branch]` |
| `3s` | 直前のコマンドの実行時間 | 黄 | `[cmd_duration]` |
| `>` | 入力位置（2 行目） | 成功時は緑、失敗時は赤 | `[character]` |

#### 表示順と改行

表示する項目と順番は、ファイル先頭の `format` で決める。`$モジュール名` を書いた順に表示され、途中の改行がそのままプロンプトの改行になる。

```toml
format = """
$username$hostname$directory$git_branch$cmd_duration
$character"""
```

- `format` に書いていないモジュールは、下のほうにセクションがあっても表示されない
- 項目を減らしたいときは、ここから `$モジュール名` を消す

#### 各セクションの設定

各モジュールの `format` で、そのモジュールの見た目を決める。`[表示する文字]($style)` と書くと、`[]` の中が `style` の色で表示される。

**ユーザー名・ホスト名**

```toml
[username]
style_user = "bold green"
format = "[$user]($style)"
show_always = true   # デフォルトでは SSH・root 以外のとき非表示になるため常に表示する

[hostname]
ssh_only = false     # デフォルトでは SSH 接続時のみ表示されるため常に表示する
style = "bold green"
format = "[@$hostname]($style)"
```

**ディレクトリ**

```toml
[directory]
home_symbol = "~"           # ホームディレクトリを ~ で表示する
truncation_length = 0       # 0 = 階層を省略しない（例: 2 にすると末尾 2 階層だけ表示）
truncate_to_repo = false    # git リポジトリ内でもリポジトリ名から始めず ~/ から表示する
style = "bold blue"
format = ":[$path]($style)[$read_only]($read_only_style)"
```

> `truncate_to_repo` がデフォルト（`true`）のままだと、git リポジトリ内では `.../dots-hyprland` のように省略される。

**git ブランチ**

```toml
[git_branch]
style = "bold purple"
symbol = ""        # ブランチ名の前のアイコンを付けない
format = " [$symbol$branch(:$remote_branch)]($style)"
```

**実行時間**

```toml
[cmd_duration]
min_time = 0       # 0 = 常に表示する（ミリ秒。2000 にすると 2 秒以上のときだけ表示）
style = "yellow"
format = " [$duration]($style)"
```

**入力位置の記号**

```toml
[character]
success_symbol = "[>](bold green)"   # 直前のコマンドが成功したとき
error_symbol = "[>](bold red)"       # 直前のコマンドが失敗したとき
```

#### 色の指定方法

- 色名: `black` `red` `green` `yellow` `blue` `purple` `cyan` `white`
- 256 色の番号: `fg:245` のように指定する
- `bold` を付けると太字、`bg:色` で背景色になる

実際にどの色で見えるかは、ターミナル（kitty など）の配色設定によって変わる。

#### tty でも使える理由

tty は Nerd Font のアイコンや絵文字を表示できない。この設定では、`format` に入っているモジュールの表示を ASCII 文字だけにしているため、tty でも文字化けしない。

> `[git_status]` などには絵文字の設定が残っているが、`format` に入れていないので表示されない。`format` に追加する場合は tty で文字化けする。

### VS Code ターミナルのフォント

フォントが `monospace` のままだと starship のアイコンが文字化けする。`~/.config/Code/User/settings.json` を編集する。

```json
"terminal.integrated.fontFamily": "'JetBrainsMono Nerd Font Mono', 'Noto Sans Mono CJK JP', monospace",
```

---

## tty の文字化け対策

tty（Linux コンソール）は日本語グリフを表示できないため、tty のときだけ英語ロケールにする。`~/.zshrc` に追記する。

```zsh
# Linux console (tty) cannot render Japanese glyphs: force English locale there
if [[ $TERM == linux ]]; then
  export LANG=en_US.UTF-8
  export LC_ALL=en_US.UTF-8
fi
```

> `starship.toml` に Nerd Font のアイコンを追加すると tty では文字化けするので注意。

---

## ソフトウェア

```bash
yay -S --needed \
    firefox zen-browser-bin google-chrome \
    docker docker-compose visual-studio-code-bin \
    proton-vpn-cli proton-pass \
    discord slack-desktop \
    vlc obs-studio
```

### Docker グループへの追加

```bash
sudo usermod -aG docker $USER
```

---

## 音が出ない場合

```bash
systemctl --user enable --now pipewire pipewire-pulse wireplumber
```

---

## ProtonVPN の自動接続

```bash
mkdir -p ~/.config/systemd/user
```

`~/.config/systemd/user/protonvpn.service` を作成し、[src/protonvpn.service](src/protonvpn.service) をコピーする。

```bash
systemctl --user daemon-reload
systemctl --user enable --now protonvpn.service
systemctl --user status protonvpn.service
```