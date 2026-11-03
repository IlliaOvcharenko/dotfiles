# Obsidian

- **Shared profiles:** store vault configuration in `obsidian/<config-name>/`.
  For example, `obsidian/default/` contains shared JSON settings and
  `community-plugins.json`, the list of enabled community plugin IDs.
- **Install manually:** close Obsidian, open a Bash session, then run:

  ```bash
  cd /path/to/vault
  install_obsidian_config default
  ```

  The current directory must contain `.obsidian/`. Vault installation is not
  managed by Dotbot. Open a new Bash session after adding the function, or source
  `bash/bashrc.d/45-obsidian.bash` from your dotfiles checkout to load it immediately.
- **Missing plugins:** requires `curl`, `python3`, and internet access. The command
  resolves IDs through Obsidian's official community-plugin registry and downloads
  the latest stable GitHub releases into the vault's `.obsidian/plugins/`.
  Allow community plugins in the vault when reopening Obsidian.
- **Plugin settings:** put shared settings in
  `obsidian/<config-name>/plugins/<plugin-id>/data.json`. The installer links this
  file only after the listed plugin is installed or confirmed already installed.
  Plugin binaries and unrelated plugin files remain vault-local.
- **Backups and repeat runs:** conflicting vault settings are moved into
  `.obsidian/.dotfiles-backup.*/`; conflicting plugin settings are backed up inside
  that plugin's folder under `.dotfiles-backup.*/data.json`. Correct links and
  installed plugins are skipped, not updated. Failed downloads are cleaned up;
  incomplete existing plugin folders are reported and left untouched.
- **Shared changes:** edits Obsidian writes through these symlinks update the files
  in dotfiles and affect every vault using the same profile. Keep vault-specific
  settings out of the shared profile.
