case ${OSTYPE:-} in
    darwin*) ;;
    *) return ;;
esac

# Homebrew uses /opt/homebrew on Apple Silicon and /usr/local on Intel Macs.
if command -v brew >/dev/null 2>&1; then
    brew_executable="$(command -v brew)"
elif [ -x /opt/homebrew/bin/brew ]; then
    brew_executable=/opt/homebrew/bin/brew
elif [ -x /usr/local/bin/brew ]; then
    brew_executable=/usr/local/bin/brew
else
    brew_executable=
fi

if [ -n "$brew_executable" ]; then
    eval "$("$brew_executable" shellenv)"
fi
unset brew_executable

export CLICOLOR="${CLICOLOR:-1}"
export BASH_SILENCE_DEPRECATION_WARNING="${BASH_SILENCE_DEPRECATION_WARNING:-1}"


[ -r "$HOME/.iterm2_shell_integration.bash" ] && . "$HOME/.iterm2_shell_integration.bash"
