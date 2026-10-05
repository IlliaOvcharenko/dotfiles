## Remote Neovim clipboard

The clipboard bridge supports this usual setup:

```text
iTerm2 -> local tmux -> SSH -> remote Neovim
```

Neovim uses the system clipboard as its unnamed register. When the bridge is
enabled, browser `Cmd-C` can be pasted in remote Neovim with `p`, and `yy` in
remote Neovim can be pasted into a local macOS app with `Cmd-V`.

The bridge is disabled by default. Toggle it with:

```text
Ctrl-b Ctrl-y
```

tmux displays `Clipboard bridge: ON` or `Clipboard bridge: OFF` after the
shortcut. The setting is server-wide and affects every session and pane in the
current tmux server.

A remote Neovim clipboard paste may time out while the bridge is disabled; use `Cmd-V` or enable the bridge first.

In iTerm2, enable **Settings -> General -> Selection -> Applications in
terminal may access clipboard** and set **Allow sending of clipboard
contents?** to **Always** for clipboard reads without confirmation.
