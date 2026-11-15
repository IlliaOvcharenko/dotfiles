---
name: dotfile-docs
description: Suggest a short docs update after changing any dotfiles-managed configuration, including Bash, tmux, Neovim, Ranger, and Pi. Use when finishing configuration or skill changes in the dotfiles repository.
---

# Configuration documentation reminder

When finishing a change to configuration, integrations, or skills in this dotfiles repository (for example `bash/`, `tmux/`, `nvim/`, `ranger/`, or `pi/`), suggest one relevant documentation update. Do not suggest this for inspection-only tasks or changes unrelated to configuration.

- For a new document, use `docs/<util-name>-<feature-name>.md` for a specific feature or `docs/<util-name>-overview.md` for a general recap. Use short, lowercase, hyphenated names: for example, `docs/pi-permissions.md`, `docs/tmux-clipboard.md`, or `docs/bash-overview.md`.
- If an existing document already covers the change, suggest updating it instead of creating a duplicate, even if its filename predates this convention.
- Keep the proposed document very short and human-readable, as a bullet list: what the feature does, how to use it, and hotkeys or commands if applicable. Omit unavailable hotkeys rather than inventing them.
- Mention the suggested path and a brief summary in your final response. Do not edit or create the doc automatically.
- If the user asks you to write the doc, follow the repository's approval policy: propose the exact file and changes, ask for explicit approval in a standalone question, and wait for confirmation before editing.
