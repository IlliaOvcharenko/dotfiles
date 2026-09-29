# Load the first Git completion script available on this laptop.
if [ -r "$HOME/.git-completion.bash" ]; then
    . "$HOME/.git-completion.bash"
elif [ -n "${HOMEBREW_PREFIX:-}" ] && [ -r "$HOMEBREW_PREFIX/etc/bash_completion.d/git-completion.bash" ]; then
    . "$HOMEBREW_PREFIX/etc/bash_completion.d/git-completion.bash"
elif [ -r /usr/share/bash-completion/completions/git ]; then
    . /usr/share/bash-completion/completions/git
fi

if [ -r "$HOME/.geo-gremlin-completion.bash" ]; then
    . "$HOME/.geo-gremlin-completion.bash"
fi
