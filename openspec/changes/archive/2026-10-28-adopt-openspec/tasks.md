# Tasks

## 1. Migrate from Agent OS
- [x] 1.1 Remove `agent-os/` and `.claude/commands/agent-os/`
- [x] 1.2 Install the `openspec-*` skills for Claude Code and OpenCode; add `CLAUDE.md`
- [x] 1.3 Check that no live reference to Agent OS remains outside `CHANGELOG.md`

## 2. Configure OpenSpec
- [x] 2.1 Fill `openspec/config.yaml` (context, rules, operations) for this module
- [x] 2.2 Fill `AGENTS.md` (project, commands)
- [x] 2.3 Pin `openspec` and node in `mise.toml`; add the `spec-validate` and `spec-setup` tasks and `scripts/openspec-setup.sh`
- [x] 2.4 Add the `validate:specs` CI job (`.gitlab/specs.yml`) and `OPENSPEC_VERSION`

## 3. Baseline specs
- [x] 3.1 Write the delta specs for `module-contract`, `volumes`, `snapshots` and `images`
- [x] 3.2 `openspec validate --all --strict` passes (same command as the `validate:specs` CI job)
- [x] 3.3 Archive the change and replace the `TBD` purposes of the main specs

## 4. Documentation
- [x] 4.1 README "Contributing": OpenSpec workflow, `mise run spec-setup`, `mise run spec-validate`
- [x] 4.2 `pre-commit run` passes on the changed files
