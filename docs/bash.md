# Bash

The Bash configuration is split into small, ordered fragments so the same
dotfiles can be used on macOS and Linux. Optional tools are detected at shell
startup, while laptop-specific paths and commands live outside the repository.

## Structure

```text
bash/
├── bash_profile
├── bashrc
├── bashrc.d/
│   ├── 10-env.bash
│   ├── 20-linux.bash
│   ├── 20-macos.bash
│   ├── 25-history.bash
│   ├── 30-prompt.bash
│   ├── 40-aliases.bash
│   └── 50-tools.bash
└── bashrc.local.example
```

Dotbot creates these links:

| Home path | Repository path | Purpose |
| --- | --- | --- |
| `~/.bash_profile` | `bash/bash_profile` | Entry point for login shells |
| `~/.bashrc` | `bash/bashrc` | Entry point for interactive Bash configuration |
| `~/.bashrc.d` | `bash/bashrc.d` | Ordered, shared configuration fragments, .d for dir|

`~/.bashrc.local` is intentionally not linked or managed by Dotbot.

## Startup order

1. A login shell reads `~/.bash_profile`.
2. `~/.bash_profile` sources `~/.bashrc`.
3. `~/.bashrc` returns immediately when the shell is not interactive.
4. Every readable `~/.bashrc.d/*.bash` file is sourced in filename order.
5. `~/.bashrc.local` is sourced last when it exists.

The numeric filename prefixes make dependencies explicit. For example,
`path_prepend` is defined by `10-env.bash` before any platform or tool fragment
uses it.

## Shared command history

- Bash keeps up to 50,000 commands in memory and 100,000 lines in the history file. Shells append to the file rather than overwriting it on exit.
- Terminals and tmux panes using the same `HISTFILE` share history. At each prompt, Bash saves new commands and reloads the history file. Press Enter in an idle pane to refresh its history.
- Run `bash-history-status` to see the mode, recording state, active file, commands in memory, and lines on disk without printing the commands themselves. Disk lines are not a command count: timestamps and multiline commands can use extra lines.
- In existing Bash sessions, run `source ~/.bashrc.d/25-history.bash` before closing them so they don't exit with the old history settings.

### Opt-in project history

- Bash starts with global history. Run `bash-enable-project-history` from anywhere inside a project under `~/work` or `~/notwork`. It switches the current shell without starting a new one.
- The first folder under either root is the project: `~/work/payments/src` uses `~/work/payments/.bash_history`. Each pane opts in separately; panes that select the same project share its history.
- If a symlink leads outside these roots, enter through the path under `~/work` or `~/notwork`. Bash uses that logical path when the physical path is outside both roots.
- Changing directories does not switch history. Only one project history can be active per shell. Run `bash-disable-project-history` to return to global history before enabling another project.
- New project history files are created with owner-only permissions. If the project is a Git repo, exclude `/.bash_history` from Git so it isn't accidentally committed.

## Prompt indicators

- **Vi mode:** `[I]` is insert mode (soft pink) and `[N]` is normal mode (sky blue). Press `Esc` to enter normal mode and `i` to return to insert mode. The labels require a newer Bash than the one bundled with macOS.
- **Conda environment:** When an environment is active, its name appears in mint green before your username. Names longer than four characters are shortened with `..` (`research` → `rese..`); `base` stays `base`. The tag disappears when no environment is active.

## Different OS

Platform fragments check `OSTYPE` and return without making changes on the
other operating system. Optional integrations also check commands and files
before using them, so a missing application should not produce startup errors.

## PATH handling

Use `path_prepend` instead of assigning to `PATH` directly:

```bash
path_prepend "$HOME/.local/bin"
```

The helper only adds existing directories and does not add a directory that is
already in `PATH`.

The macOS fragment discovers Homebrew in this order:

1. `brew` already available in `PATH`;
2. `/opt/homebrew/bin/brew` on Apple Silicon;
3. `/usr/local/bin/brew` on Intel macOS.

After `brew shellenv` runs, Homebrew-managed paths use `HOMEBREW_PREFIX` rather
than a processor-specific absolute prefix.

## Supported overrides

The shared configuration recognizes these variables when they are already set
before `~/.bashrc` is sourced:

| Variable | Default | Purpose |
| --- | --- | --- |
| `EDITOR` | `nvim` | Default command-line editor |
| `VISUAL` | Value of `EDITOR` | Default visual editor |
| `CONDA_EXE` | Auto-detected | Exact path to the Conda executable |
| `CONDA_HOME` | `~/miniconda3` | Conda installation directory |
| * `NODE_HOME` | Homebrew `node@24` | Alternative Node installation directory on macOS |
| * `SUBLIME_BIN` | Sublime Text's standard macOS CLI directory | Alternative directory containing the Sublime Text CLI |
| `CLICOLOR` | `1` on macOS | BSD command color output |
| `BASH_SILENCE_DEPRECATION_WARNING` | `1` on macOS | Hides Apple's default-shell warning |

Because `~/.bashrc.local` loads after the managed fragments, variables that
control fragment initialization must come from the parent environment. For a
one-off installation that cannot provide them early, initialize that tool
directly in `~/.bashrc.local` instead.

## Laptop-specific configuration

Copy the example file on each laptop:

```bash
cp ~/dotfiles/bash/bashrc.local.example ~/.bashrc.local
```

Adjust the source path if the repository is cloned somewhere else. It can hold
machine-specific aliases, functions, and extra paths:

```bash
path_prepend "$HOME/path/to/tool/bin"
```

Do not commit `~/.bashrc.local`, and do not store passwords, tokens, or private
keys in it. Use it for paths and references to an appropriate secret store.


Dotbot links the managed files into the home directory.
