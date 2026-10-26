# NeoVIM

## Copy file location

In normal mode, press **backtick → y → l** (`<leader>yl`) to copy the current
file path, line, and character column to the system clipboard. Example:

```text
src/main.py:42:7
```

The path is relative to Neovim's current working directory when the file is
inside it; otherwise, it is absolute. Line and character column numbers start
at 1. Neovim shows a confirmation with the copied location. Unnamed buffers
show a warning instead.

Could be useful while working with LLM coding agents.
