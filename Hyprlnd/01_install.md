# やること
end-4さんの`dots-hyprland`を使ってHyprlandの環境を構築する。

[「end_4's dots-hyprland (GitHub)」](https://github.com/end-4/dots-hyprland)

# インストール
Arch Linuxのインストールは[01_base-install.md](01_base-install.md)を参照。<br>
インストール後のセットアップは[02_setup.md](02_setup.md)を参照。

## 必要なもののインストール
```bash
pacman -S --needed git base-devel

git clone https://github.com/end-4/dots-hyprland
cd dots-hyprland
./setup install
```
確認しながら進め、再起動。

## Hyprlandの起動
```bash
start-hyprland
```

---

おわり。

---

# 追加のセットアップ (必要に応じて)
QuickShellやキーバインドの設定は、[02_setup.md](02_setup.md)を参照。