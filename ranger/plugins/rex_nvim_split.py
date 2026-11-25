"""Open Ranger's highlighted file or directory in a Rex editor pane."""

import os
import shutil
import subprocess

import ranger.api
from ranger.api.commands import Command

from .nvim import open_in_nvim, rex_editor_blocks, rex_editor_sockets


class rex_open_nvim_right(Command):
    """Reuse the tab's Rex editor, or create one to the right if absent."""

    def execute(self):
        pane = os.environ.get("REX_BLOCK")
        if not pane:
            self.fm.notify("This command requires a Rex pane", bad=True)
            return

        entry = self.fm.thisfile or self.fm.thisdir
        if entry is None:
            self.fm.notify("No file or directory to open", bad=True)
            return
        path = os.path.abspath(entry.path)
        if os.path.isdir(path):
            cwd = path
        elif os.path.isfile(path):
            cwd = os.path.dirname(path)
        else:
            self.fm.notify("Cannot open this item as a file or directory: " + path, bad=True)
            return

        editors = rex_editor_blocks(pane)
        if editors is None:
            self.fm.notify("Cannot check this Rex tab for an editor pane", bad=True)
            return
        if editors:
            handled, error = open_in_nvim([path], rex_editor_sockets(editors))
            if error:
                self.fm.notify(error, bad=True)
            elif not handled:
                self.fm.notify("An editor pane already exists, but its Neovim socket is unavailable",
                               bad=True)
            return

        nvim = shutil.which("nvim")
        if not nvim:
            self.fm.notify("Neovim (nvim) is not on Ranger's PATH", bad=True)
            return

        # Start the same Neovim that Ranger sees, without shell quoting or expansion.
        args = [
            "rex", "--autostart=false", "--timeout=5s", "split",
            "-b", pane, "--split=right", "--label", "editor", "-c", cwd,
            "--shell=none", "--", os.path.abspath(nvim), "--", path,
        ]
        try:
            result = subprocess.run(
                args, stdout=subprocess.DEVNULL, stderr=subprocess.PIPE,
                text=True, errors="replace", timeout=8, check=False,
            )
        except subprocess.TimeoutExpired:
            self.fm.notify("Rex timed out; check for a new pane before retrying", bad=True)
            return
        except OSError as exc:
            self.fm.notify("Cannot run Rex: " + str(exc), bad=True)
            return
        if result.returncode != 0:
            detail = result.stderr.strip() or "exit status %d" % result.returncode
            self.fm.notify("Cannot open Rex editor pane: " + detail, bad=True)


_previous_hook_init = ranger.api.hook_init


def hook_init(fm):
    _previous_hook_init(fm)
    if os.environ.get("REX_BLOCK"):
        fm.execute_console("map gN rex_open_nvim_right")


ranger.api.hook_init = hook_init
