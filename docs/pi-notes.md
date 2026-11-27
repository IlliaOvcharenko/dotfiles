# Pi Harness

## Start options
- --no-extensions (disables all)
- --no-sandbox to keep the modes but drop OS sandboxing
- -e <path> can keep selected extensions using

- pi --verbose - startup Context section lists all loaded instruction files with their paths.

- pi -e npm:pi-subagents - run with subagets, project based subagets could be place under ./pi/agenst subfolder.

## Model metadata and compaction

- **Model metadata** (`contextWindow`, `maxTokens`, and `cost`): edit `pi/agent/model-metadata.json`. Put non-public overrides in `pi/agent/model-metadata.local.json`.
- **Compaction** (when Pi summarizes and how much recent history it keeps): edit `pi/agent/compaction.json`. Put non-public overrides in `pi/agent/compaction.local.json`. For per-model budgets, use exact `provider/modelId` keys under `modelOverrides`.
- Both `.local.json` files are Git-ignored. Local values win when they set the same field as the shared file.
- Run `./install`, then `/reload` in Pi. The installer merges metadata into `~/.pi/agent/models.json` and builds the Git-ignored `pi/agent/settings.generated.json` from shared settings and the compaction files. Edit the source files, not the generated file.
- Check the effective context and output limits with `pi --list-models`.

## Todo
- keep answer short and brief, few concise sentences is enough.
explain details if user explicitly ask for.


