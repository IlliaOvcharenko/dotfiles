# Bash configuration

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

## Installation

From the repository root, run:

```bash
./install
```

Dotbot links the managed files into the home directory. Open a new shell after
installation, or reload the current interactive shell:

```bash
source ~/.bashrc
```
