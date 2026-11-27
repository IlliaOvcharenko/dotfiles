"""Merge shared and private model metadata into Pi's local models.json."""

import json
import os
from pathlib import Path
from tempfile import NamedTemporaryFile


def merge_fields(current, overrides):
    """Keep unspecified fields, including nested fields such as cost.input."""
    for key, value in overrides.items():
        if isinstance(value, dict) and isinstance(current.get(key), dict):
            merge_fields(current[key], value)
        else:
            current[key] = value


def apply_overrides(config, path, *, optional=False):
    try:
        source = json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError:
        if optional:
            return
        raise
    except json.JSONDecodeError as exc:
        raise SystemExit(f"{path.name}: {exc}") from None

    providers = config.setdefault("providers", {})
    for provider, settings in source["providers"].items():
        if settings.keys() != {"modelOverrides"}:
            raise SystemExit(f"{path.name}: {provider} must contain only modelOverrides")
        overrides = providers.setdefault(provider, {}).setdefault("modelOverrides", {})
        for model, fields in settings["modelOverrides"].items():
            merge_fields(overrides.setdefault(model, {}), fields)


agent_dir = Path(os.environ.get("PI_CODING_AGENT_DIR") or "~/.pi/agent").expanduser()
target = (agent_dir / "models.json").resolve()

try:
    original = target.read_text(encoding="utf-8")
except FileNotFoundError:
    original = "{}"

config = json.loads(original)
source_dir = Path(__file__).parent
apply_overrides(config, source_dir / "model-metadata.json")
local = source_dir / "model-metadata.local.json"
if not local.exists():
    # Keep older checkouts' private files working until they are renamed.
    local = source_dir / "model-overrides.local.json"
apply_overrides(config, local, optional=True)

updated = json.dumps(config, indent=2, ensure_ascii=False) + "\n"
if updated != original:
    target.parent.mkdir(parents=True, exist_ok=True)
    # Replace atomically with a private file: local config can contain API keys.
    with NamedTemporaryFile(dir=target.parent, mode="w", encoding="utf-8", delete=False) as temp:
        try:
            temp.write(updated)
            temp.close()
            os.replace(temp.name, target)
        finally:
            Path(temp.name).unlink(missing_ok=True)
