# 追加セットアップ

[01_base-install.md](01_base-install.md) 完了後の追加設定。必要に応じて実施する。

> このファイルと [Hyprland/02_setup.md](Hyprland/02_setup.md) の設定は、[setup.sh](setup.sh) でまとめて適用できる。詳しくは [README.md](README.md) を参照。

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

## 電源ボタン・蓋を閉じたときの動作

`01_base-install.md` の手順でハイバネートを有効化した場合に、以下の動作にする。

| 操作 | 動作 |
|---|---|
| 電源ボタンを押す | ハイバネート（休止） |
| 電源ボタンを長押し（約 5 秒） | シャットダウン |
| 蓋を閉じる | サスペンド → 30 分後にハイバネート |

> サスペンドは状態をメモリに保存する（復帰が速いが、待機中も電力を使う）。ハイバネートは状態をディスク（スワップ）に保存して電源を切る（復帰は遅いが、電力を使わない）。`suspend-then-hibernate` は両方を組み合わせたもの。

ハイバネートが使えるか確認する（`"yes"` ならOK）。

```bash
busctl call org.freedesktop.login1 /org/freedesktop/login1 org.freedesktop.login1.Manager CanHibernate
```

### Hyprland・CLI の場合

`/etc/systemd/logind.conf` を直接編集せず、ドロップインファイルを作成する（`logind.conf` より優先される）。

`/etc/systemd/logind.conf.d/power-key.conf`（[src/systemd/power-key.conf](src/systemd/power-key.conf)）

```ini
[Login]
HandlePowerKey=hibernate
HandlePowerKeyLongPress=poweroff
HandleLidSwitch=suspend-then-hibernate
HandleLidSwitchExternalPower=suspend-then-hibernate
```

サスペンドからハイバネートに移行するまでの時間を設定する。

`/etc/systemd/sleep.conf.d/hibernate-delay.conf`（[src/systemd/hibernate-delay.conf](src/systemd/hibernate-delay.conf)）

```ini
[Sleep]
HibernateDelaySec=30min
```

logind に設定を再読み込みさせる。

```bash
sudo systemctl kill -s HUP systemd-logind
```

> `systemctl restart systemd-logind` はログイン中のセッションが落ちることがあるため使わない。
>
> 機種によっては、長押しで logind より先にハードウェアの強制電源オフが働く。

### GNOMEやKDEの場合

`logind.conf` の設定はDEが上書きするため、DE側の電源管理設定から「蓋を閉じたとき」の動作を `サスペンド後にハイバネート` に変更する。

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

# 指紋登録
fprintd-enroll
```

> fprintd は必要なときに自動で起動するため、`systemctl enable` は不要（できない）。

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

`zsh-autosuggestions` と `zsh-syntax-highlighting` は zim のデフォルトの `~/.zimrc` に含まれている。`~/.zimrc` の末尾に以下を追記する。

```
zmodule Aloxaf/fzf-tab
```

> 同じモジュールを 2 回書くと二重に読み込まれるので、追記前に `grep zmodule ~/.zimrc` で確認する。

```bash
zimfw install
```

### kitty のシェル設定変更

`~/.config/kitty/kitty.conf` を編集する。

```
shell zsh
```

`Ctrl+V` で貼り付けられるようにする。fish は自分で `Ctrl+V` を貼り付けに割り当てているが、zsh では `Ctrl+V` は貼り付けにならない（kitty 標準の貼り付けは `Ctrl+Shift+V`）。

```
map ctrl+v    paste_from_clipboard
```

編集後は `Ctrl+Shift+F5` で設定を再読み込みする。

> dots-hyprland をインストール・更新すると `kitty.conf` が上書きされ、`shell fish` に戻り、`Ctrl+V` の割り当ても消える。dots-hyprland の後に設定すること。
>
> kitty の中で動かすアプリ（vim の矩形選択など）でも `Ctrl+V` が貼り付けになる。

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

## 日本語フォントの優先設定

`noto-fonts-cjk` には日本語・韓国語・中国語（簡体字・繁体字・香港）の 5 種類が入っているが、優先順位の設定がないため、日本語の文字に韓国語版（Noto Sans CJK KR）が使われる。一部の漢字（「直」「骨」「刃」など）が日本の字形と違う形になる。

`LANG` が `en_US.UTF-8` だと言語からも日本語版が選ばれないので、`LANG` を変えずに fontconfig で日本語版を優先する。

`~/.config/fontconfig/fonts.conf`（[src/fontconfig/fonts.conf](src/fontconfig/fonts.conf)）

```xml
<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
<fontconfig>
  <!-- Disable subpixel rendering -->
  <match target="font">
    <edit name="rgba" mode="assign">
      <const>none</const>
    </edit>
  </match>

  <!-- Prefer Japanese glyphs for CJK (Latin stays Noto Sans/Serif/Mono) -->
  <alias>
    <family>sans-serif</family>
    <prefer>
      <family>Noto Sans</family>
      <family>Noto Sans CJK JP</family>
    </prefer>
  </alias>
  <alias>
    <family>serif</family>
    <prefer>
      <family>Noto Serif</family>
      <family>Noto Serif CJK JP</family>
    </prefer>
  </alias>
  <alias>
    <family>monospace</family>
    <prefer>
      <family>Noto Sans Mono</family>
      <family>Noto Sans Mono CJK JP</family>
    </prefer>
  </alias>
</fontconfig>
```

- 英字は今まで通り Noto Sans / Noto Serif / Noto Sans Mono で表示し、それらにない日本語の文字だけ CJK JP で表示する
- CJK JP を先頭にすると、英字まで CJK JP のフォントで表示されてしまう

キャッシュを更新して確認する（アプリは再起動すると反映される）。

```bash
fc-cache -f
fc-match "sans-serif:lang=ja"        # "Noto Sans CJK JP" ならOK
fc-match "monospace:charset=3042"    # 「あ」を表示するフォント。"Noto Sans Mono CJK JP" ならOK
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
    nemo \
    firefox zen-browser-bin google-chrome \
    docker docker-compose visual-studio-code-bin github-cli \
    proton-vpn-cli proton-pass-bin \
    discord slack-desktop \
    vlc obs-studio
```

### Docker の有効化

```bash
# 最初に docker コマンドを使ったときに自動で起動する
sudo systemctl enable --now docker.socket

# sudo なしで docker を使えるようにする（再ログイン後に反映）
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