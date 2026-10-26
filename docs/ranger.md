# Ranger

## Open files in an existing NeoVIM (under same tmux window)

When ranger and Neovim run in the same tmux window, opening a
text file with Right, Enter, or `l` opens it in the existing Neovim. The `E`
command also uses this integration. 

Focus stays in ranger without suspending or redrawing its interface.

The plugin finds Neovim through its socket address, which the Neovim config
registers on its tmux pane. If several editors are available, it uses the first
reachable one in pane-index order. If none is available, ranger uses its normal
editor behavior. Other file associations, such as image and PDF viewers, are
unchanged.

For multiple selected files, the first is displayed and the others are added as
listed buffers, loaded when visited.

