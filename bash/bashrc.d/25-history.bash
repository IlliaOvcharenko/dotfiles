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
    local cwd home project_cwd logical_home relative root target previous previous_exported=0

    if [[ -n ${_dotfiles_global_history_file:-} ]]; then
        printf 'Project history is already enabled: %s\nRun bash-disable-project-history before enabling another project.\n' \
            "${HISTFILE:-(unset)}" >&2
        return 1
    fi
    if [[ -z ${HISTFILE:-} || ! -o history ]]; then
        printf 'Enable Bash history and set HISTFILE before switching history.\n' >&2
        return 1
    fi

    cwd=$(builtin pwd -P) || return 1
    home=$(builtin cd -P -- "$HOME" && builtin pwd -P) || return 1
    home=${home%/}
    project_cwd=$cwd
    case $project_cwd in
        "$home"/work/*|"$home"/notwork/*) ;;
        *)
            # A symlink under an allowed root can point outside the home directory.
            project_cwd=$(builtin pwd -L) || return 1
            logical_home=${HOME%/}
            case $project_cwd in
                "$home"/work/*|"$home"/notwork/*) ;;
                "$logical_home"/work/*|"$logical_home"/notwork/*) home=$logical_home ;;
                *)
                    printf 'Run bash-enable-project-history from a project under ~/work or ~/notwork.\n' >&2
                    return 1
                    ;;
            esac
            ;;
    esac

    # The first directory beneath work/notwork is the project, even from a subfolder.
    relative=${project_cwd#"$home"/}
    root=${relative%%/*}
    relative=${relative#*/}
    target=$home/$root/${relative%%/*}/.bash_history

    if [[ ! -e $target && ! -L $target ]]; then
        # Noclobber lets another shell create the file first without truncating it.
        (umask 077; set -o noclobber; : > "$target") 2>/dev/null || :
    fi
    if [[ -L $target || ! -f $target || ! -O $target || ! -r $target || ! -w $target ]]; then
        printf 'Cannot use project history file: %s\n' "$target" >&2
        return 1
    fi

    if [[ $HISTFILE != "$target" && ! $HISTFILE -ef $target ]]; then
        previous=$HISTFILE
        [[ $previous = /* ]] || previous=$cwd/$previous
        case $(declare -p HISTFILE) in
            'declare -'*x*' HISTFILE='*) previous_exported=1 ;;
        esac
        _dotfiles_switch_history "$target" || return 1
        _dotfiles_global_history_file=$previous
        _dotfiles_global_history_exported=$previous_exported
        # The project setting is an opt-in for this shell, not its children.
        export -n HISTFILE
    fi
    printf 'Project history: %s\n' "$HISTFILE"
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
