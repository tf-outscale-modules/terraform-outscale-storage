# Proposal

## Why

Planning in this module is done with Agent OS (`agent-os/standards/`, `agent-os/product/`, `agent-os/specs/` and `.claude/commands/agent-os/`). Those standards are an unversioned copy of rules that are now published as pinned OpenSpec stores (`quality`, `repository`, `terraform`), and the sibling modules (`vault`, `keycloak`, `gitlab-management`) already plan with OpenSpec. Migrating aligns this module with them and gives future changes a baseline contract to write delta specs against.

## What Changes

- Remove Agent OS: `agent-os/` (product docs, two shaped specs, the standards and their index) and `.claude/commands/agent-os/` (5 commands). The standards are replaced by the referenced stores; the product docs and the two historical specs (module creation, removal of OOS from the module) stay available in git history.
- Configure `openspec/config.yaml`: reference the `quality`, `repository` and `terraform` stores pinned to a tag, and add storage-specific `context`, per-artifact `rules` and `operations` guidance.
- Add `AGENTS.md` (project summary, non-negotiables, standards lookup, workflow, precedence, commands) and `CLAUDE.md` importing it.
- Write the baseline capability specs under `openspec/specs/`, describing the module **as it behaves today**.
- Tooling: pin the `openspec` CLI (and node) in `mise.toml`, add `spec-validate` and `spec-setup` tasks, add `scripts/openspec-setup.sh`, install the `openspec-*` skills for Claude Code and OpenCode, and validate specs in CI through the `validate:specs` job of `.gitlab/specs.yml`.
- README "Contributing" points to the OpenSpec workflow.
- No change to any `.tf` file, input, output or resource: semver **patch**, shipped with the next tag. `CHANGELOG.md` is not touched (git-cliff generates it from commit subjects).

## Capabilities

### New Capabilities
- `module-contract`: Terraform/OpenTofu and provider constraints, no provider or backend block, the input set with types and defaults, feature flags, common tags and the output set.
- `volumes`: BSU volumes and their attachments to VMs.
- `snapshots`: snapshots (from a volume, a copy or an import) and snapshot export tasks.
- `images`: images (OMI) and image export tasks.

### Modified Capabilities
<!-- none: openspec/specs/ is empty -->

## Impact

- Removed: `agent-os/`, `.claude/commands/agent-os/`.
- Added: `AGENTS.md`, `CLAUDE.md`, `openspec/` (config, archived change, main specs), `.claude/skills/openspec-*`, `.opencode/skills/openspec-*`, `scripts/openspec-setup.sh`, `.gitlab/specs.yml`.
- Modified: `mise.toml` (openspec and node pins, two tasks), `.gitlab-ci.yml` (include), `.gitlab/global.yml` (`OPENSPEC_VERSION`), README "Contributing".
- Contributors need the stores registered once per machine (`mise run spec-setup`); CI needs no store, it only validates `openspec/`.
- Module consumers: none.
