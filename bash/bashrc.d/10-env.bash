# Add a directory to PATH once, and only when it exists.
path_prepend() {
    [ "$#" -eq 1 ] && [ -d "$1" ] || return 0

    case ":${PATH:-}:" in
        *":$1:"*) ;;
        *) PATH="$1${PATH:+:$PATH}" ;;
    esac
}

path_prepend "$HOME/.local/bin"

export PATH
export EDITOR="${EDITOR:-nvim}"
export VISUAL="${VISUAL:-$EDITOR}"
