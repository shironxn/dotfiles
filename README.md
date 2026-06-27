# dotfiles

Arch Linux · Sway · Fish · Foot · Fuzzel · Neovim · SwayOSD

## structure

```
nvim/      text editor
sway/      window manager
swayosd/   OSD (volume/brightness/mic)
fish/      shell
foot/      terminal
fuzzel/    launcher
lazygit/   git tui
fastfetch/ system info
yay/       aur helper
wal/       pywal colors & templates
pkg-lists/ package backups
```

## install

```bash
git clone https://github.com/shironxn/dotfiles.git ~/dotfiles
```

deploy manual via symlink or use `backup.sh`.

## notes

- API keys & tokens go in `~/.config/fish/conf.d/secrets.fish` — not in repo.
- nvim config is managed by LazyVim; the embedded git repo is excluded.
