HISTSIZE=50000
HISTFILESIZE=100000
shopt -s histappend

_dotfiles_switch_history() {
    local target=$1 previous=$HISTFILE

    if [[ -e $target && ( ! -f $target || ! -r $target ) ]]; then
        printf 'Cannot read history file: %s\n' "$target" >&2
        return 1
    fi

    # Save pending commands to the old file before replacing the in-memory list.
    builtin history -a || return 1
    HISTFILE=$target || return 1
    builtin history -c
    if [[ -e $target ]] && ! builtin history -r; then
        HISTFILE=$previous
        builtin history -c
        [[ ! -f $previous ]] || builtin history -r
        return 1
    fi
}

bash-enable-project-history() {
    _dotfiles_enable_project_history
}

_dotfiles_enable_project_history() {
    local start_dir=${1:-} cwd target previous previous_exported=0

    if [[ -n ${_dotfiles_global_history_file:-} ]]; then
        [[ -n $start_dir ]] || printf 'Project history is already enabled: %s\nRun bash-disable-project-history before enabling another project.\n' \
            "${HISTFILE:-(unset)}" >&2
        return 1
    fi
    if [[ -z ${HISTFILE:-} || ! -o history ]]; then
        [[ -n $start_dir ]] || printf 'Enable Bash history and set HISTFILE before switching history.\n' >&2
        return 1
    fi

    cwd=$(builtin pwd -P) || return 1
    target=${start_dir:-$cwd}
    target=${target%/}/.bash_history
    previous=$HISTFILE
    [[ $previous = /* ]] || previous=${cwd%/}/$previous

    if [[ $previous == "$target" || $previous -ef $target ]]; then
        [[ -n $start_dir ]] || printf 'This folder already uses your active history file: %s\n' "$target" >&2
        return 1
    fi

    if [[ -z $start_dir && ! -e $target && ! -L $target ]]; then
        # Noclobber lets another shell create the file first without truncating it.
        (umask 077; set -o noclobber; : > "$target") 2>/dev/null || :
    fi
    if [[ -L $target || ! -f $target || ! -O $target || ! -r $target || ! -w $target ]]; then
        [[ -n $start_dir ]] || printf 'Cannot use project history file: %s\n' "$target" >&2
        return 1
    fi

    case $(declare -p HISTFILE) in
        'declare -'*x*' HISTFILE='*) previous_exported=1 ;;
    esac
    if [[ -n $start_dir ]]; then
        # Bash loads its initial history after reading the startup files.
        HISTFILE=$target || return 1
    else
        _dotfiles_switch_history "$target" || return 1
    fi
    _dotfiles_global_history_file=$previous
    _dotfiles_global_history_exported=$previous_exported
    # Child shells select history independently at startup.
    export -n HISTFILE
    if [[ -n $start_dir ]]; then
        printf 'Project history enabled: %s\n' "$HISTFILE"
    else
        printf 'Project history: %s\n' "$HISTFILE"
    fi
}

bash-disable-project-history() {
    if [[ -z ${_dotfiles_global_history_file:-} ]]; then
        printf 'Project history is not enabled.\n'
        return 0
    fi
    if [[ -z ${HISTFILE:-} || ! -o history ]]; then
        printf 'Enable Bash history and set HISTFILE before switching history.\n' >&2
        return 1
    fi

    _dotfiles_switch_history "$_dotfiles_global_history_file" || return 1
    if [[ ${_dotfiles_global_history_exported:-0} == 1 ]]; then
        export HISTFILE
    fi
    unset _dotfiles_global_history_file _dotfiles_global_history_exported
    printf 'Global history: %s\n' "$HISTFILE"
}

bash-history-status() {
    local mode=global recording=on file=${HISTFILE:-} entries disk_lines

    [[ -z ${_dotfiles_global_history_file:-} ]] || mode=project
    [[ -o history ]] || recording=off

    # Tag entry headers so a multiline command still counts as one entry.
    entries=$(HISTTIMEFORMAT='[dotfiles-entry] ' builtin history |
        command awk '/^[[:blank:]]*[0-9]+[ *][[:blank:]]+\[dotfiles-entry\] / { count++ } END { print count+0 }') || return 1

    if [[ -z $file ]]; then
        disk_lines='unavailable (HISTFILE not set)'
    elif [[ -f $file && -r $file ]]; then
        disk_lines=$(command awk 'END { print NR+0 }' < "$file") || disk_lines=unavailable
    elif [[ ! -e $file && ! -L $file ]]; then
        disk_lines='0 (file not found)'
    else
        disk_lines=unavailable
    fi

    printf 'History mode: %s\nRecording: %s\nHistory file: %s\nCommands in memory: %s\nLines on disk: %s\n' \
        "$mode" "$recording" "${file:-(unset)}" "$entries" "$disk_lines"
}

_dotfiles_sync_history() {
    local status=$?
    if [[ -n ${HISTFILE:-} && -o history ]] && builtin history -a &&
        [[ -f $HISTFILE && -r $HISTFILE ]]; then
        # Incremental reads can skip other shells' entries after an append.
        builtin history -c
        builtin history -r
    fi
    return "$status"
}

_dotfiles_install_history_hook() {
    local hook=_dotfiles_sync_history entry

    # Bash 5.1+ runs each element of an indexed PROMPT_COMMAND array.
    if (( BASH_VERSINFO[0] > 5 || (BASH_VERSINFO[0] == 5 && BASH_VERSINFO[1] >= 1) )); then
        case $(declare -p PROMPT_COMMAND 2>/dev/null) in
            'declare -'*a*' PROMPT_COMMAND='*)
                for entry in "${PROMPT_COMMAND[@]}"; do
                    [ "$entry" = "$hook" ] && return 0
                done
                PROMPT_COMMAND+=("$hook")
                return 0
                ;;
        esac
    fi

    # Keep existing scalar hooks first, and don't add ours twice on re-source.
    case $'\n'"${PROMPT_COMMAND-}"$'\n' in
        *$'\n'"$hook"$'\n'*) ;;
        *) PROMPT_COMMAND="${PROMPT_COMMAND:+$PROMPT_COMMAND$'\n'}$hook" ;;
    esac
}

_dotfiles_install_history_hook
unset -f _dotfiles_install_history_hook
