case ${OSTYPE:-} in
    linux*) ;;
    *) return ;;
esac

if command -v nvidia-smi >/dev/null 2>&1; then
    alias wnsmi='watch -n 0.5 nvidia-smi'
fi
