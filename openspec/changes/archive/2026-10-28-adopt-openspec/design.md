# Design

## Context

The module is small (one `main.tf` with six resource types, 529 lines of HCL in total) and its contract is stable: three feature flags, six map inputs, two sensitive API key inputs and one output per resource family. Agent OS held generic standards plus two historical shaped specs; nothing there describes the module's current behaviour.

## Decisions

- **Standards come from pinned stores, not from the repository.** `openspec/config.yaml` references `quality`, `repository` and `terraform` at a tag; `mise run spec-setup` registers them once per machine. Agent OS standards are dropped rather than ported, so there is a single source of truth.
- **Skills for both agents.** The `openspec-*` skills are installed in `.claude/skills/` (Claude Code) and `.opencode/skills/` (OpenCode); `AGENTS.md` is the shared entry point and `CLAUDE.md` imports it.
- **CI job `validate:specs`.** `.gitlab/specs.yml` runs `openspec validate --all --strict` with the CLI version pinned by `OPENSPEC_VERSION`; the same command is `mise run spec-validate` locally.
- **Capability split follows the feature flags.** `module-contract` holds what applies to the whole module (constraints, inputs, common tags, outputs); `volumes` (`enable_volume`), `snapshots` (`enable_snapshot`) and `images` (`enable_image`) each hold their resources, validation and export tasks.
- **Specs describe the released behaviour only.** Validation blocks and preconditions are specified with a rejected input; behaviour that looked inconsistent was left out of the specs and reported instead of being fixed (this change touches no `.tf` file).
- **CHANGELOG stays generated.** `CHANGELOG.md` is produced by git-cliff from commit subjects (`mise run changelog`, `.cliff.toml`), so `AGENTS.md` and `config.yaml` ask for commit subjects that read as CHANGELOG lines instead of a hand-written `[Unreleased]` entry.
- **Tests are not specs.** The unit tests (`tests/main.tftest.hcl`, plan only) are described in `config.yaml`; the specs describe the observable contract.

## Risks

- A spec could drift from the code. Mitigation: future behaviour changes go through `/openspec-propose`, and archiving merges deltas into `openspec/specs/`.
