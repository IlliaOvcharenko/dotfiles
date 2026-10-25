"""Send ranger's editor actions to Neovim in the same tmux window."""

import json
import os
import subprocess

import ranger.api
from ranger.ext.rifle import squash_flags


def run_command(args):
    try:
        result = subprocess.run(
            args, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL,
            universal_newlines=True, timeout=3, check=False,
        )
        return result.stdout if result.returncode == 0 else None
    except (OSError, subprocess.TimeoutExpired):
        return None


def read_reply(result):
    """Neovim may write its reply to either captured output stream."""
    for output in (result.stdout, result.stderr):
        for candidate in [output.strip()] + output.splitlines():
            try:
                status = json.loads(candidate)
                # Also accept a JSON string containing the JSON reply.
                if isinstance(status, str):
                    status = json.loads(status)
            except ValueError:
                continue
            if isinstance(status, dict) and ("ok" in status or "available" in status):
                return status
    return None


def open_in_nvim(files):
    """Return (handled, error); only an unavailable editor permits fallback."""
    pane = os.environ.get("TMUX_PANE")
    if not os.environ.get("TMUX") or not pane or not files:
        return False, None

    # Query the window containing ranger's pane, rather than the active window.
    panes = run_command([
        "tmux", "list-panes", "-t", pane, "-F",
        "#{pane_id}\t#{@nvim_server}",
    ])
    if panes is None:
        return False, None

    # tmux returns panes in index order: the first reachable editor wins.
    for line in panes.splitlines():
        target, separator, address = line.partition("\t")
        if not separator or not address or target == pane:
            continue

        client = ["nvim", "--headless", "--server", address, "--remote-expr"]
        # Pass paths as data, not Ex commands or simulated keystrokes. Also check
        # ownership so stale metadata cannot send files to a different pane.
        payload = json.dumps([target, [os.path.abspath(path) for path in files]])
        lua = (
            "local pane, paths = unpack(_A); "
            "if vim.env.TMUX_PANE ~= pane then "
            "return vim.fn.json_encode({available = false}) end; "
            "local ok, err = pcall(function() "
            "local buffers = {}; "
            "for _, path in ipairs(paths) do "
            "local buf = vim.fn.bufadd(path); vim.bo[buf].buflisted = true; "
            "table.insert(buffers, buf) end; "
            # Switching to the first buffer loads it normally. Leave additional
            # selected files unloaded until visited instead of reading them all.
            "vim.api.nvim_set_current_buf(buffers[1]); end); "
            "return vim.fn.json_encode({ok = ok, error = not ok and tostring(err) or ''})"
        )
        expression = "luaeval('%s', json_decode('%s'))" % (
            ("(function() " + lua + " end)()").replace("'", "''"),
            payload.replace("'", "''"),
        )
        try:
            # File reads and FileType/LSP hooks can take several seconds.
            # Wait for an explicit reply instead of timing out
            # after the file has already opened and launching a second editor.
            result = subprocess.run(
                client + [expression], stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                universal_newlines=True, check=False,
            )
        except OSError:
            return False, None

        status = read_reply(result)
        if isinstance(status, dict) and status.get("available") is False:
            continue
        if isinstance(status, dict) and status.get("ok") is True:
            return True, None
        # --remote-expr reports a connection failure as E247 and never starts
        # an editor locally. Only this failure is safe to retry or fall back.
        if status is None and result.returncode != 0 and "E247:" in (
                result.stderr + result.stdout):
            continue
        if isinstance(status, dict) and status.get("error"):
            detail = status["error"]
        else:
            detail = result.stderr.strip() or result.stdout.strip() or "no reply received"
        return True, "Neovim reported an error while opening: %s" % detail
    return False, None


previous_hook_init = ranger.api.hook_init


def hook_init(fm):
    previous_hook_init(fm)
    previous_execute = fm.rifle.execute

    def execute(files, number=0, label=None, flags="", mimetype=None):
        # Intercept before rifle launches a shell or suspends ranger's UI.
        # Use the actual requested files and opening rule, including explicit
        # choices from "open_with". Keep privileged opens on the normal path.
        for count, command, rule_label, rule_flags in fm.rifle.list_commands(files, mimetype):
            if (label and label == rule_label) or (not label and count == number):
                if (command == '${VISUAL:-$EDITOR} -- "$@"'
                        and "r" not in squash_flags(flags + rule_flags)):
                    handled, error = open_in_nvim(files)
                    if error:
                        fm.notify(error, bad=True)
                    if handled:
                        return None
                break
        return previous_execute(files, number, label, flags, mimetype)

    fm.rifle.execute = execute


ranger.api.hook_init = hook_init
