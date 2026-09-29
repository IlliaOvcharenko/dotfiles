# Support the standard Conda locations while allowing CONDA_HOME or CONDA_EXE
# to select a different installation.
conda_executable=
conda_home="${CONDA_HOME:-$HOME/miniconda3}"

if [ -n "${CONDA_EXE:-}" ] && [ -x "$CONDA_EXE" ]; then
    conda_executable="$CONDA_EXE"
elif command -v conda >/dev/null 2>&1; then
    conda_executable="$(command -v conda)"
elif [ -x "$conda_home/bin/conda" ]; then
    conda_executable="$conda_home/bin/conda"
fi

if [ -n "$conda_executable" ]; then
    if conda_setup="$("$conda_executable" shell.bash hook 2>/dev/null)"; then
        eval "$conda_setup"
    elif [ -r "$conda_home/etc/profile.d/conda.sh" ]; then
        . "$conda_home/etc/profile.d/conda.sh"
    fi
    unset conda_setup
fi

unset conda_executable conda_home
