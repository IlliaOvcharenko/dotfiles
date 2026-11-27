"""Render Pi settings with shared compaction settings and private overrides."""

import json
import os
from pathlib import Path
from tempfile import NamedTemporaryFile


TOKEN_FIELDS = {"reserveTokens", "keepRecentTokens"}


def read_object(path, *, optional=False):
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError:
        if optional:
            return {}
        raise
    except json.JSONDecodeError as exc:
        raise SystemExit(f"{path.name}: {exc}") from None
    if not isinstance(value, dict):
        raise SystemExit(f"{path.name}: expected a JSON object")
    return value


def apply_compaction(config, source, path):
    def apply_tokens(target, fields):
        for field, value in fields.items():
            if field not in TOKEN_FIELDS or type(value) is not int or not 0 <= value <= 2**53 - 1:
                raise SystemExit(f"{path.name}: invalid token setting: {field}")
            target[field] = value

    for field, value in source.items():
        if field == "enabled" and isinstance(value, bool):
            config[field] = value
        elif field == "modelOverrides" and isinstance(value, dict):
            models = config.setdefault(field, {})
            for model, fields in value.items():
                provider, _, model_id = model.partition("/")
                if not provider or not model_id or not isinstance(fields, dict):
                    raise SystemExit(f"{path.name}: expected a settings object for {model!r} (provider/modelId)")
                apply_tokens(models.setdefault(model, {}), fields)
        else:
            apply_tokens(config, {field: value})


source_dir = Path(__file__).resolve().parent
shared = source_dir / "compaction.json"
local = source_dir / "compaction.local.json"
target = source_dir / "settings.generated.json"

compaction = {}
apply_compaction(compaction, read_object(shared), shared)
local_settings = read_object(local, optional=True)
# Older local files contained just the per-model map, without a wrapper.
if local_settings and all("/" in key for key in local_settings):
    local_settings = {"modelOverrides": local_settings}
apply_compaction(compaction, local_settings, local)

# Preserve Pi-written preferences not explicitly managed in shared settings.json.
config = read_object(target, optional=True)
config.update(read_object(source_dir / "settings.json"))
config["compaction"] = compaction
updated = json.dumps(config, indent=2, ensure_ascii=False) + "\n"
if not target.is_symlink() and target.exists() and target.read_text(encoding="utf-8") == updated:
    raise SystemExit(0)

# Replace rather than writing through an existing link to the shared settings.
with NamedTemporaryFile(dir=source_dir, mode="w", encoding="utf-8", delete=False) as temp:
    try:
        temp.write(updated)
        temp.close()
        os.replace(temp.name, target)
    finally:
        Path(temp.name).unlink(missing_ok=True)
