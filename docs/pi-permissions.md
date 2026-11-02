# Pi permissions: quick reference

## Install

- Install extension `pi install npm:pi-permission-modes`
- Linux needs `bubblewrap`, `socat`, and `ripgrep`; macOS uses `sandbox-exec`.

- Copy permission config file.
  ```bash
  mkdir -p "$HOME/.pi/agent/permission-mode"
  cp permission-mode.candidate.json "$HOME/.pi/agent/permission-mode/permission-mode.json"
  ```

- Use `/sandbox` to check that the sandbox is working.
- `/perm init` writes stock defaults; it does not install this candidate.
- `$HOME` adapts to your account. `$HOME/miniconda3` is not automatic toolchain detection: if your Python tools live elsewhere, update `sandbox.allowRead` in Plan/ApproveConfirm/Approve/Build to that specific folder. `$CONDA_PREFIX` is not a supported path placeholder.
- `show_plan` is hidden because this version only displays files under `plan/`, not root `PLAN.md`. If you ask the agent to save a plan, open `PLAN.md` in your text editor to read it, or ask the agent to explain it in chat. Planning in chat does not require a saved file.

## Modes

| Mode | Use it for | What the agent can change |
|---|---|---|
| **Plan** | Normal chat, questions, reading code, review, planning | Only Markdown files, and only when you ask. No plan file is required. |
| **ApproveConfirm** | Reviewing changes with a smaller model (`/perm approve-confirm`) | Project file tools can make explicitly approved changes; Bash asks before commands and stays read-only, so it cannot delete files. |
| **Approve** | Reviewing changes with a model you trust to follow approval instructions (`/perm approve`) | After explicit approval, project file tools and sandboxed Bash can make the proposed changes, including file deletion. Bash does not ask for an additional command approval. |
| **Build** | Working on a task without approving each edit or command | Project files, including changes made by Bash commands. Protected files remain blocked. |
| **YOLO** | Work inside an already isolated, disposable container | Anything your user account can access. No sandbox or permission prompts. Never use on your normal host. |

- **Plan is the configured startup mode** for new sessions. A startup flag or inherited `PI_PERMISSION_MODE` can override it. Ordinary chat does not create files.
- If you ask to save a plan, the agent uses `PLAN.md` in the project root.
- Plan allows `rg` and `ls` Bash commands without prompting for project exploration; other Bash commands ask. ApproveConfirm asks before Bash commands. Both modes prevent Bash from changing project files.
- Approve runs local, sandboxed Bash commands without a command prompt; any file change still requires a specific proposal and explicit chat confirmation first.
- Build runs normal project Bash commands without asking. Git, package installation, and other blocked commands remain blocked. New network destinations still need approval.
- In Build, the agent must not change permission configuration. Switch to Approve to review and explicitly authorize such changes. This is an agent instruction, not a blanket filesystem block; protected-path and outside-project checks still apply.
- The extension still provides its built-in `default` mode. This config does not customize it. Avoid it: it does not use the restrictions described here.

- The **sandbox** uses operating-system restrictions to limit what Bash commands and the programs they launch can read, write, and access over the network. It is enabled in **Plan, ApproveConfirm, Approve, and Build**: Plan/ApproveConfirm prevent Bash from changing project files; Approve/Build allow project writes, plus designated temporary folders. All four block configured private paths and require approval for new network destinations; system/toolchain reads are still allowed, so this is not complete isolation. File tools such as `read`, `edit`, and `write` follow separate permission rules, not the Bash sandbox. **YOLO disables the sandbox.**

## Switch modes / reset decisions

```text
/perm plan             Chat, inspect, review, or plan
/perm approve-confirm  Require explicit approval; read-only Bash asks before commands
/perm approve          Require explicit approval; sandboxed project Bash runs without asking
/perm build            Allow autonomous project work
/sandbox         Show the actual sandbox settings and whether it is working
```

- **Alt+M** cycles Plan → ApproveConfirm → Approve → Build. It never cycles into YOLO.
- A resumed session keeps its previous mode. Start with `pi --perm plan` to force Plan.
- `/perm clear-approvals` makes Pi forget permissions you allowed for this session, so those actions ask again. It also removes paths you explicitly blocked for this session, returning them to the normal config rules. It does **not** undo edits or remove permanent config rules.

**ApproveConfirm and Approve: how permission works**

The explicitly approved file-change proposal is sufficient. No separate plan document or planning step is required.

1. Agent lists the **exact files** and briefly explains the changes.
2. Agent asks a **separate approval question**.
3. You clearly confirm, for example: **“Yes, apply these changes.”**

“Fix it”, “do X”, switching modes, or approving a general plan is not enough. Until you confirm the specific proposal, the agent may only read, search, explain, or show proposed diffs in chat. Approval covers creation, deletion, renaming, and overwriting only for the proposed files and changes. Any additional or revised changes outside that scope—including changes to an already approved file—require a new proposal and explicit confirmation.

After chat confirmation, `edit` and `write` to project files do not show an additional tool prompt. In Approve, sandboxed Bash can also make approved project changes (including deletions) without a command prompt; it can technically write to other project files too. In ApproveConfirm, Bash remains read-only even after approval, so deletions need another mode or a manual action. Outside-project file access still asks, and protected paths remain blocked. One request may contain several edits—review the proposal for them all. The chat approval sequence is an instruction to the agent; the extension does not independently check the conversation for a “yes”. In Approve, an agent that ignores this instruction could modify or delete project files without your approval.

## Files: what is accessible?

In Plan, ApproveConfirm, Approve, and Build, before editing an existing file, the agent must:
- Re-read its current contents immediately before editing.
- Use targeted replacements, not a full-file rewrite, for wording changes.
- Preserve unrelated content and your edits.
- Stop and ask you before proceeding if the file differs from what it expected.

These are agent instructions, not checks enforced by the sandbox.

- **Project folder:** reading is allowed. Changes depend on the mode above.
- **Files outside the project:** file tools ask before accessing them, unless another rule blocks them. The extension allows reading its reference documentation without asking.
- **Your home folder (`$HOME`):** Bash normally cannot read its contents. Two folders are made readable again: the current project and `$HOME/miniconda3`, so the installed Python tools can run. That read permission does not itself allow writes to Miniconda. If Miniconda is inside the current project, Approve/Build's project-write permission may cover it. Specific credential files remain blocked.
- **System files:** Bash can still read tools, libraries, and other locations not explicitly blocked. This is **not** a rule that allows reading only the project. Other users' folders and mounted drives are not automatically hidden.
- **Temporary files:** even with project-only writes configured, the extension gives commands some temporary folders outside the project for their own working files. Use the supplied `$TMPDIR`; do not assume any location under `/tmp` is writable.
- **Protected files:** file tools cannot edit `.git`, `.env`, `.env.*`, `node_modules`, shell startup files, and other protected paths. File-tool blocks do not guarantee that a script cannot read a secret stored inside the project. Keep secrets out of agent projects.
- **Plan:** the tool rules allow editing any project Markdown file. The instruction to edit only when asked is narrower, but is not a separate enforced file rule.

## Bash / Python / environment

- **Plan:** `rg` (including `rg --files`) searches project contents and lists files; `ls` lists directories. These commands run without a Bash permission prompt. Other Bash commands ask. Explicit outside-project access can still prompt and run unsandboxed if approved; do not approve such an escape. The `read` file tool remains allowed for project files.
- **ApproveConfirm:** Bash asks before running a new executable and is read-only. Allowing Python for the whole session also allows later Python scripts, not just the script you first saw.
- **Approve:** local Bash commands run automatically in a project-writable sandbox, but the agent must obtain explicit approval before any command that changes files, including deletion. Use this mode only with models you trust to follow that instruction.
- **Build:** ordinary project commands run automatically inside the sandbox. The sandbox limits their file writes and network access.
- **Warning: outside-project commands.** If Pi detects a command accessing an outside path, it can offer to run it **without the sandbox**. Approving that prompt removes the sandbox's file and network protection for that run. In Plan, ApproveConfirm, Approve, and Build, the agent is instructed never to request or use this unsandboxed escape. Do not approve it; run the operation yourself if needed. Separately approved outside-project access through file tools remains available, subject to other permission rules. Also refuse prompts saying the sandbox is disabled or unavailable.
- Start Pi from a terminal where your intended Python/Conda environment is already active. It uses that terminal's exported settings and PATH. Terminal aliases and shell state are not carried between commands.
- The agent must not activate, create, install, update, remove, or repair packages/environments. If something is missing, it explains what **you** should install. Common package managers, administrator commands, Docker/Podman, and SSH/SCP/SFTP are blocked.
- **Environment secrets:** if you run `export API_KEY=...` before starting Pi, commands launched by Pi can read that value. Blocking credential files does not hide values already passed through the environment. Do not ask the agent to print all variables (`env`, `printenv`), and start Pi without keys or tokens it does not need.
- Command-name blocks are not a complete check of what scripts do. Review unfamiliar scripts before running them.

## Git / network / other tools

- **Git:** agent `git` and `gh` commands are blocked, including status/diff/log. File tools cannot access `.git` folders. Bash's explicit filesystem block covers the project-root `.git`, not every nested repository a script could access. A chat “yes” does not override a blocked command. Run Git yourself in a terminal; user-entered `!git ...` runs on the host, outside the agent-tool policy.
- **Network:** Bash initially has no approved websites/hosts. You must approve each new destination. Once approved, a command can send data there, not just download from it.
- `/net status` shows network permissions; `/net allow example.com` allows a host for the session; `/net reset` forgets session host approvals and refusals.
- Keep network filtering on. **Alt+N** or `/net open` opens network access for the session; `/net restrict` turns filtering back on. **Allow forever** saves permission in the global config.
- Local servers are not freely available by default. macOS blocks direct local connections/listening with this config; Linux uses a separate network environment, so behavior differs.
- In Plan, ApproveConfirm, Approve, and Build, `show_plan`, `powershell`, `codemode`, and `tool_search` are hidden from the agent. Hidden tools are unavailable to the model; blocked tools may remain visible, but their execution is denied.
- **Web tools on demand:** in Plan, ApproveConfirm, Approve, and Build, `web_enable` is allowed without a permission prompt. It exposes the configured `pi-web-access` tools when needed, keeping the initial tool list small. Enabling them does not approve their use: web search still asks, and other extension tools follow their own permission rules. The extension's own network-approval tool asks separately.
- The Bash sandbox does not control Pi's model-provider connections or protect against a malicious extension. Install only trusted extensions.


## YOLO
**YOLO does not create a container.** Use it only after setting up isolation yourself. Do not expose your home, credentials, Docker socket, or valuable host files to that container. Files on a writable host mount can still be changed.
