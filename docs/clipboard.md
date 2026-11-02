## Clipboard behaviour
Nvim clipboard are synced with system clipboard in almost every env:

| Setup | Clipboard path |
| --- | --- |
| Local Neovim, with or without local tmux | Neovim uses the local system clipboard provider. The tmux clipboard bridge is not needed. |
| iTerm2 → local tmux → SSH → remote Neovim | Neovim uses OSC 52. Clipboard requests pass through SSH and local tmux to iTerm2; programmatic clipboard access requires the local tmux bridge to be ON. |
| iTerm2 → SSH → remote Neovim (no tmux) | Neovim uses OSC 52 directly through SSH to iTerm2. There is no tmux bridge to switch on or off. |
| iTerm2 → SSH → remote tmux → remote Neovim | Neovim uses its tmux clipboard provider. Whether `p` can access the Mac clipboard depends on the remote tmux configuration and any intervening tmux sessions; it is not guaranteed by this configuration alone. |


### Tmux clipboard bridge for ssh connection

The clipboard bridge supports this usual setup:

```text
iTerm2 -> local tmux -> SSH -> remote Neovim
```

When the bridge is enabled, client system clipboard can be pasted in remote Neovim with `p`, and `yy` in remote Neovim can be pasted into a local macOS app with `Cmd-V`.

The bridge is disabled by default. Toggle it with:

```text
Ctrl-b Ctrl-y
```

tmux displays `Clipboard bridge: ON` or `Clipboard bridge: OFF` after the
shortcut. The setting is server-wide and affects every session and pane in the current tmux server.

The bridge is OFF by default so programs on a remote machine cannot use this
local tmux server to request the Mac clipboard just because you connected over
SSH. This makes local tmux a useful opt-in boundary for this clipboard route:
enable it while working with a trusted host, then disable it again. The setting
applies to every pane in the tmux server, and it does not protect direct SSH
connections that bypass local tmux.

A remote Neovim clipboard paste may time out while the bridge is disabled; use `Cmd-V` or enable the bridge first.

In iTerm2, enable **Settings -> General -> Selection -> Applications in
terminal may access clipboard** and set **Allow sending of clipboard
contents?** to **Always** for clipboard reads without confirmation.
