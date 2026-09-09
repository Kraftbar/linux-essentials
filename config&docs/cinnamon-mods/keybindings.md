# Cinnamon keybinding tweaks

## Ctrl+Shift+W closes any focused window

By default Ctrl+Shift+W only works inside apps that implement it themselves
(e.g. closing a browser tab). This adds it as a system-wide "close window"
shortcut alongside the default Alt+F4.

```
gsettings set org.cinnamon.desktop.keybindings.wm close "['<Alt>F4', '<Shift><Control>w']"
```

Check current value:

```
gsettings get org.cinnamon.desktop.keybindings.wm close
```

Revert to default (Alt+F4 only):

```
gsettings set org.cinnamon.desktop.keybindings.wm close "['<Alt>F4']"
```

Applied 2026-08-20, no relog needed (Cinnamon picks up dconf changes live).
