# pi-powerline-footer auto-detect only knows iterm/wezterm/kitty/ghostty/alacritty/kaku
# (icons.ts -> hasNerdFonts). foot is not in that list, so it silently falls back to
# ASCII glyphs even though foot.ini uses JetBrainsMono Nerd Font Mono. Force it on.
set -gx POWERLINE_NERD_FONTS 1
