# Hyprland インストール手順

end-4 氏の [dots-hyprland](https://github.com/end-4/dots-hyprland) を使って Hyprland 環境を構築する手順。

事前に以下を完了しておくこと。

- [01_base-install.md](../01_base-install.md) : Arch Linux のベースインストール
- [02_setup.md](../02_setup.md) : 追加セットアップ（任意）

---

## 1. インストール

```bash
pacman -S --needed git base-devel

git clone https://github.com/end-4/dots-hyprland
cd dots-hyprland
./setup install
```

確認しながら進め、完了したら再起動する。

---

## 2. Hyprland の起動

```bash
start-hyprland
```

---

## 次のステップ

QuickShell やキーバインドなどの追加設定は [02_setup.md](02_setup.md) を参照。