# Pi permissions: quick reference

## Install / migrate

- Use **pi-permission**, not `pi-permission-modes`. Enable only one permission extension: the new extension does not load the old configuration or session state.
- Run these commands yourself to replace the old package:
  ```bash
  pi remove npm:pi-permission-modes
  pi install git:git@github-personal:IlliaOvcharenko/pi-permission
  ```
- The Git source uses your `github-personal` SSH alias and requires access to that repository. It is already declared in `pi/agent/settings.json`.
- Requirements: Node.js **22.18.0+** and Pi with package support. Linux also needs `bubblewrap`, `socat`, and `ripgrep` on PATH; macOS uses the OS sandbox. Install missing dependencies yourself.
- Dotbot links `pi/agent/pi-permission/config.json` to `~/.pi/agent/pi-permission/config.json`. This is the version-2 global configuration; do not copy the old `permission-mode` candidate file.
- Restart Pi after migration, then inspect `/pi-permission status` and `/pi-permission config`. Use `/reload` after subsequent configuration changes.

## Modes and commands

- **Plan** is the default: chat, inspect, review, and plan. Only requested Markdown edits are allowed; Bash cannot change project files. No plan file is created unless requested.
- **Approve** requires an exact filename proposal, a standalone approval question, and your explicit confirmation before file changes. Bash can write within configured project/scratch boundaries, but command prompts still apply.
- **Build** removes the mode's separate chat-approval step for requested work. Bash prompts and filesystem restrictions still apply. Repository instructions can impose stricter approval requirements.
- **YOLO** disables permission checks and the Bash sandbox. It requires explicit UI confirmation and is excluded from normal mode cycling. Use only in an already isolated, disposable environment: it does not create a container.
- **Alt+M** cycles Plan → Approve → Build. ApproveConfirm and the old `default` mode are not part of this extension.

```text
/pi-permission plan             Chat, inspect, review, or plan
/pi-permission approve          Require a specific file-change proposal and confirmation
/pi-permission build            Work without the mode's separate chat-approval step
/pi-permission status           Inspect mode, safety, config paths, and load errors
/pi-permission config           Inspect resolved rules and sandbox profile
/pi-permission clear-approvals  Forget session tool approvals; does not undo edits
```

- Start a new session with `pi --pi-permission plan` to select Plan. Resumed sessions restore their saved mode; the startup flag does not override that saved selection.
- Chat confirmation and re-reading files before edits are **agent instructions**, not mechanically verified conversation checks. Tool prompts and filesystem gates are separate safeguards.

## Current permission rules

- **Bash prompts:** parsed exploration commands (`ls`, `grep`, `fd`, `fdfind`, `rg`, `find`, `pwd`) can run without prompting. Other commands ask in Plan, Approve, and Build. Unsupported syntax cannot gain a narrow automatic allow.
- **Sandbox:** every non-YOLO Bash command must use the OS sandbox. Missing dependencies or sandbox failure refuse execution; there is no unsandboxed fallback. Plan permits scratch writes only; Approve/Build permit project and scratch writes, subject to restrictions. Use the supplied `$TMPDIR`.
- **File tools:** reads within the project, session scratch, and Pi's `skills`/`prompts` directories are allowed; other locations ask. Configured denies still win. Writes are limited to project/scratch, with a Markdown-only restriction in Plan.
- **Protected paths:** configured restrictions cover SSH/Pi credentials, directories named `archive`, `notes`, `.git`, or `credentials`, and writes to paths such as `.env*`, `node_modules`, and shell startup files.
- **Bash reads are broader than file-tool read roots.** Do not treat the sandbox as project-only read isolation. Approved scripts are not prompted for every file they open.
- **Network is unrestricted**, including local services. The old `/net` commands, host approvals, and Alt+N network toggle do not apply.
- **Custom extension tools are not OS-sandboxed** and unspecified tools allow by default. Configure explicit ask/deny rules where needed; install only trusted extensions.
- **Environment:** use inherited PATH/Python and an already active Conda environment. The agent must not manage environments/packages or dump credentials. Environment variables passed to Pi remain accessible to launched commands.
- **Git:** shared extension guidance permits only clone, but this repository's `AGENTS.md` forbids all agent Git operations. Run Git yourself. Prompt guidance is not an executable blacklist.

## Project policy

- Optional `.pi/pi-permission.json` is an authoritative project overlay, not merely extra restrictions. Review its contents before granting trust: it can replace global groups and broaden ordinary permissions.
- `/pi-permission trust` reloads and reviews pending project policy; `/pi-permission revoke` revokes persistent trust. Changed policy requires renewed review.
- Effective rules come from package defaults → global config → trusted project config. `/pi-permission config` shows the resolved policy; project overlays can change the rules summarized above.
