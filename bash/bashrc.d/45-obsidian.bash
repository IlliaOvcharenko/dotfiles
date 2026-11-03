# Resolve the repository through the fragment, including Dotbot's symlinked directory.
_obsidian_dotfiles_root=$(
    fragment=${BASH_SOURCE[0]}
    hops=0
    while :; do
        fragment_dir=$(cd -P -- "$(dirname -- "$fragment")" && pwd) || exit 1
        fragment="$fragment_dir/$(basename -- "$fragment")"
        [ -L "$fragment" ] || break
        hops=$((hops + 1))
        [ "$hops" -le 40 ] || exit 1
        target=$(readlink -- "$fragment") || exit 1
        case "$target" in
            (/*) fragment=$target ;;
            (*) fragment="$fragment_dir/$target" ;;
        esac
    done
    cd -- "$fragment_dir/../.." && pwd -P
)

# Run at the vault root. Only settings present in the selected profile are linked.
install_obsidian_config() (
    if [ "$#" -ne 1 ]; then
        printf 'Usage: install_obsidian_config <config-name>\n' >&2
        return 1
    fi
    case "$1" in
        ''|.|..|*/*)
            printf 'Invalid Obsidian config name: %s\n' "$1" >&2
            return 1
            ;;
    esac

    local config_dir source destination name backup_dir=''
    config_dir="${_obsidian_dotfiles_root:-}/obsidian/$1"
    if [ -z "${_obsidian_dotfiles_root:-}" ] || [ ! -d "$config_dir" ]; then
        printf 'Obsidian config not found: %s\n' "$1" >&2
        return 1
    fi
    if [ ! -d .obsidian ]; then
        printf 'Run this command at a vault root containing .obsidian/.\n' >&2
        return 1
    fi

    if [ -f "$config_dir/community-plugins.json" ]; then
        local dependency
        for dependency in curl python3; do
            if ! command -v "$dependency" >/dev/null 2>&1; then
                printf 'Missing dependency: %s. Install it before running this command.\n' "$dependency" >&2
                return 1
            fi
        done
    fi

    # Include hidden profile entries without changing the caller's shell options.
    shopt -s dotglob nullglob
    local sources=("$config_dir"/*)
    if [ "${#sources[@]}" -eq 0 ]; then
        printf 'Obsidian config is empty: %s\n' "$1" >&2
        return 1
    fi

    for source in "${sources[@]}"; do
        name=${source##*/}
        # Plugin settings are linked individually only after installation succeeds.
        [ "$name" = plugins ] && continue
        destination="$PWD/.obsidian/$name"
        if [ -L "$destination" ] && [ "$(readlink -- "$destination")" = "$source" ]; then
            printf 'Already linked: %s\n' "$name"
            continue
        fi
        if [ -e "$destination" ] || [ -L "$destination" ]; then
            if [ -z "$backup_dir" ]; then
                backup_dir=$(mktemp -d "$PWD/.obsidian/.dotfiles-backup.XXXXXX") || return 1
                printf 'Backing up existing settings to: %s\n' "$backup_dir"
            fi
            mv -- "$destination" "$backup_dir/$name" || return 1
        fi
        if ! ln -s -- "$source" "$destination"; then
            # Restore this entry if creating its replacement failed.
            if [ -n "$backup_dir" ] && { [ -e "$backup_dir/$name" ] || [ -L "$backup_dir/$name" ]; }; then
                mv -- "$backup_dir/$name" "$destination"
            fi
            return 1
        fi
        printf 'Linked: %s\n' "$name"
    done

    [ -f "$config_dir/community-plugins.json" ] || return 0
    python3 - "$config_dir/community-plugins.json" "$PWD/.obsidian/plugins" <<'PY'
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import tempfile


REGISTRY_URL = "https://raw.githubusercontent.com/obsidianmd/obsidian-releases/master/community-plugins.json"


def download(url, destination=None):
    command = [
        "curl", "--fail", "--location", "--silent", "--show-error",
        "--retry", "2", "--connect-timeout", "15", "--max-time", "120",
        "--proto", "=https", "--proto-redir", "=https",
    ]
    if destination is not None:
        command.extend(["--output", str(destination)])
    result = subprocess.run(command + ["--url", url], capture_output=True)
    if result.returncode:
        detail = result.stderr.decode("utf-8", errors="replace").strip()
        raise RuntimeError("Download failed: {}: {}".format(url, detail))
    return result.stdout


def link_plugin_settings(plugin_id, destination):
    source = Path(sys.argv[1]).parent / "plugins" / plugin_id / "data.json"
    if not os.path.lexists(source):
        return
    if not source.is_file():
        raise ValueError("Shared plugin settings must be a file: {}".format(source))
    target = destination / "data.json"
    if target.is_symlink() and os.readlink(target) == str(source):
        print("Plugin settings already linked: " + plugin_id, flush=True)
        return

    backup = None
    if os.path.lexists(target):
        backup_dir = Path(tempfile.mkdtemp(prefix=".dotfiles-backup.", dir=str(destination)))
        backup = backup_dir / "data.json"
        target.rename(backup)
        print("Backed up plugin settings to: {}".format(backup), flush=True)
    try:
        target.symlink_to(source)
    except OSError:
        if backup is not None and not os.path.lexists(target):
            backup.rename(target)
        raise
    print("Linked plugin settings: " + plugin_id, flush=True)


def install_plugins():
    with open(sys.argv[1], encoding="utf-8") as handle:
        plugin_ids = json.load(handle)
    if not isinstance(plugin_ids, list) or any(
        not isinstance(plugin_id, str)
        or not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9_-]*", plugin_id)
        for plugin_id in plugin_ids
    ):
        raise ValueError("community-plugins.json must contain a list of safe plugin IDs")
    if not plugin_ids:
        return 0

    plugins_dir = Path(sys.argv[2])
    if plugins_dir.is_symlink():
        raise ValueError("Refusing to install into a symlinked plugins/ directory; keep it vault-local")
    plugins_dir.mkdir(exist_ok=True)
    pending = []
    failed = False
    for plugin_id in dict.fromkeys(plugin_ids):
        destination = plugins_dir / plugin_id
        if os.path.lexists(destination):
            if destination.is_symlink():
                print("Symlinked plugin folder left untouched: {}. Keep plugin folders vault-local.".format(destination), file=sys.stderr)
                failed = True
            elif (destination / "manifest.json").is_file() and (destination / "main.js").is_file():
                print("Plugin already installed: " + plugin_id, flush=True)
                try:
                    link_plugin_settings(plugin_id, destination)
                except (OSError, ValueError) as error:
                    print("Failed to link settings for {}: {}".format(plugin_id, error), file=sys.stderr)
                    failed = True
            else:
                print("Incomplete plugin left untouched: {}. Move it aside and retry.".format(destination), file=sys.stderr)
                failed = True
        else:
            pending.append(plugin_id)
    if not pending:
        return int(failed)

    registry = json.loads(download(REGISTRY_URL))
    if not isinstance(registry, list):
        raise ValueError("Invalid community-plugin registry")
    repositories = {
        entry.get("id"): entry.get("repo")
        for entry in registry if isinstance(entry, dict)
    }
    for plugin_id in pending:
        try:
            repository = repositories.get(plugin_id)
            if not isinstance(repository, str) or not re.fullmatch(
                r"[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+", repository
            ):
                raise ValueError("Plugin has no valid repository in the official registry")
            release = json.loads(download("https://api.github.com/repos/{}/releases/latest".format(repository)))
            assets = {
                asset["name"]: asset["browser_download_url"]
                for asset in release["assets"]
                if asset.get("name") in ("manifest.json", "main.js", "styles.css")
            }
            if not {"manifest.json", "main.js"}.issubset(assets):
                raise ValueError("Latest release is missing manifest.json or main.js")

            # Stage on the same filesystem, then publish only a complete plugin.
            with tempfile.TemporaryDirectory(prefix=".install-", dir=str(plugins_dir)) as staging:
                payload = Path(staging) / plugin_id
                payload.mkdir()
                for name, url in assets.items():
                    if not isinstance(url, str) or not url.startswith(
                        "https://github.com/{}/releases/download/".format(repository)
                    ):
                        raise ValueError("Unexpected release asset URL")
                    download(url, payload / name)
                with (payload / "manifest.json").open(encoding="utf-8") as handle:
                    manifest = json.load(handle)
                if not isinstance(manifest, dict) or manifest.get("id") != plugin_id or not manifest.get("version"):
                    raise ValueError("Downloaded manifest has an invalid ID or version")
                if (payload / "main.js").stat().st_size == 0:
                    raise ValueError("Downloaded main.js is empty")
                destination = plugins_dir / plugin_id
                if os.path.lexists(destination):
                    raise ValueError("Plugin appeared during installation; left untouched")
                payload.rename(destination)
            print("Installed plugin: {} ({})".format(plugin_id, manifest["version"]), flush=True)
            link_plugin_settings(plugin_id, destination)
        except (OSError, ValueError, KeyError, TypeError, RuntimeError) as error:
            print("Failed to install/configure {}: {}".format(plugin_id, error), file=sys.stderr)
            failed = True
    return int(failed)


try:
    sys.exit(install_plugins())
except (OSError, ValueError, KeyError, TypeError, RuntimeError) as error:
    print("Plugin installation failed: {}".format(error), file=sys.stderr)
    sys.exit(1)
PY
)
