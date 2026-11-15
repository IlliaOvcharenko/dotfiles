"""Send ranger's editor actions to Neovim in the same tmux or Rex window."""

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


def editor_panes():
    """Yield (pane ID, RPC address, ownership environment variable)."""
    pane = os.environ.get("TMUX_PANE")
    if os.environ.get("TMUX") and pane:
        # Prefer the inner multiplexer when tmux itself runs inside Rex.
        panes = run_command([
            "tmux", "list-panes", "-t", pane, "-F",
            "#{pane_id}\t#{@nvim_server}",
        ])
        for line in (panes or "").splitlines():
            target, separator, address = line.partition("\t")
            if separator and address and target != pane:
                yield target, address, "TMUX_PANE"
        return

    session = os.environ.get("REX_SESSION")
    pane = os.environ.get("REX_BLOCK")
    if not session or not pane:
        return
    result = run_command(["rex", "block", "ls", "-s", session, "--json"])
    try:
        blocks = json.loads(result or "{}").get("blocks", [])
        own = next((block for block in blocks if block["block_id"] == pane), None)
        if not own or not own.get("window_id"):
            return
        for block in blocks:
            target = block["block_id"]
            if (target == pane or block.get("label") != "editor"
                    or block.get("window_id") != own["window_id"]
                    or block.get("host_id") != own.get("host_id")):
                continue
            # IDs are used as filenames only after rejecting path separators.
            key = target[6:]
            if not target.startswith("block:") or not key or any(
                    char not in "0123456789abcdef-" for char in key):
                continue
            path = os.path.expanduser("~/.cache/rex-nvim/%s.json" % key)
            try:
                with open(path, encoding="utf-8") as stream:
                    server = json.load(stream)
                if (server.get("session") == session and server.get("block") == target
                        and isinstance(server.get("address"), str) and server["address"]):
                    yield target, server["address"], "REX_BLOCK"
            except (OSError, ValueError, AttributeError):
                continue
    except (ValueError, TypeError, KeyError, AttributeError):
        return


def open_in_nvim(files):
    """Return (handled, error); only an unavailable editor permits fallback."""
    if not files:
        return False, None

    for target, address, owner_variable in editor_panes():
        client = ["nvim", "--headless", "--server", address, "--remote-expr"]
        # Pass paths as data, not Ex commands or simulated keystrokes. Also check
        # ownership so stale metadata cannot send files to a different pane.
        payload = json.dumps([owner_variable, target,
                              [os.path.abspath(path) for path in files]])
        lua = (
            "local owner_variable, pane, paths = unpack(_A); "
            "if vim.env[owner_variable] ~= pane then "
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
                editor_rule = command == '${VISUAL:-$EDITOR} -- "$@"'
                # macOS's default open rule sends YAML to its GUI association.
                yaml_open = (not label and number == 0
                             and command == 'open -- "$@"' and files
                             and all(os.path.splitext(path)[1].lower() in (".yaml", ".yml")
                                     for path in files))
                if (editor_rule or yaml_open) and "r" not in squash_flags(flags + rule_flags):
                    handled, error = open_in_nvim(files)
                    if error:
                        fm.notify(error, bad=True)
                    if handled:
                        return None
                break
        return previous_execute(files, number, label, flags, mimetype)

    fm.rifle.execute = execute


ranger.api.hook_init = hook_init
