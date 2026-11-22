# Readline updates the mode label when the keymap changes, without rebuilding PS1.
# Older Readline versions (including macOS's stock Bash) may not support these settings.
{
    # Readline's \1 and \2 mark color escapes as zero-width.
    bind 'set vi-ins-mode-string "\1\e[1;91m\2[\1\e[0;38;5;218m\2I\1\e[1;91m\2]\1\e[0m\2 "' &&
        bind 'set vi-cmd-mode-string "\1\e[1;91m\2[\1\e[0;38;5;75m\2N\1\e[1;91m\2]\1\e[0m\2 "' &&
        bind 'set show-mode-in-prompt on'
    # Give Escape-prefixed key sequences a short window before treating Esc as standalone.
    bind 'set keyseq-timeout 50'
} 2>/dev/null

_dotfiles_conda_prompt() {
    [ -n "${CONDA_PREFIX:-}" ] || return 0

    local env_name=${CONDA_DEFAULT_ENV:-$CONDA_PREFIX}
    env_name=${env_name##*/}
    if [ "${#env_name}" -gt 4 ]; then
        printf '%s.. ' "${env_name:0:4}"
    else
        printf '%s ' "$env_name"
    fi
}

# Keep the Conda tag expansion literal in PS1 so it reflects the current environment.
uprompt() {
    local chroot_name=
    [ -n "${debian_chroot:-}" ] && chroot_name="($debian_chroot)"
    PS1='\[\e]0;\u@\h: \w\a\]'"$chroot_name"'\[\033[0;38;5;114m\]$(_dotfiles_conda_prompt)\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
}

dprompt() {
    PS1='\[\033[1;91m\][ \[\033[0;38;5;114m\]$(_dotfiles_conda_prompt)\[\033[0;33m\]\u\[\033[32m\]@\[\033[36m\]\h \[\033[95m\]\w \[\033[1;91m\]]\[\033[0;90m\]\$ \[\033[m\]'
}

sprompt() {
    PS1='\[\033[1;91m\][ \[\033[0;38;5;114m\]$(_dotfiles_conda_prompt)\[\033[0;33m\]\u \[\033[95m\]\W \[\033[1;91m\]]\[\033[0;90m\]\$ \[\033[m\]'
}

dprompt
