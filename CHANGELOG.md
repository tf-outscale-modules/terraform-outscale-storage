# Changelog

All notable changes to this project will be documented in this file.

## [1.3.0] - 2026-11-25
- Add volume termination snapshot, image import and image/snapshot sharing

New opt-in inputs, all null by default so existing configurations plan
unchanged. volumes take termination_snapshot_name (a snapshot is taken
before the volume is destroyed; it is not managed by the module). images
take architecture, file_location and root_device_name to register an OMI
from a snapshot or a manifest, and launch_permission to share it with
account IDs or, explicitly, publicly (check public_sharing warns).
snapshots take create_volume_permission, accounts only; the provider never
revokes snapshot access, so revocation is manual (SECURITY.md).

Verified on a live account with provider 1.9.0: empty second plan,
reordered account IDs do not replace anything. The image-source validation
message now lists the new sources. Minor release, provider stays ~> 1.8.
- Document export API key in state, protect module tags, add Name tags and input validation

A check and a new SECURITY.md cover the export osu_api_key.secret_key
landing in state (no write-only argument in the provider). Project,
Environment and ManagedBy can no longer be overridden by tags; images
and export tasks get a Name tag. Images require vm_id or
source_image_id and project_name must not be blank. volume_links.tags
is documented as ignored. Upgrade: existing resources get an in-place
tag update.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
- Move from Agent OS to OpenSpec and publish the baseline specs

Planning moves from Agent OS to OpenSpec: agent-os/ is removed and the
engineering standards now come from the quality, repository and terraform
OpenSpec stores. openspec/config.yaml follows the terraform-module profile
(stores pinned at quality v1.2.6, repository v4.1.0, terraform v1.2.6) and
AGENTS.md, imported by CLAUDE.md, routes to them. openspec/specs/ holds the
baseline specification of the module as released, produced by the archived
adopt-openspec change. The openspec-* skills are installed for Claude Code
and OpenCode, openspec 1.14.3 and node are pinned in mise.toml with the
spec-validate and spec-setup tasks, and the validate:specs CI job runs
openspec validate --all --strict.

CI: mise 2026.10.17 resolves tools through mise-versions.jdx.dev instead of
the rate-limited api.github.com, and the pre-commit caches are keyed on the
toolchain files instead of the branch, so a toolchain change starts a fresh
cache. The module contract is unchanged.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
- feat: add image boot modes, mandatory vTPM and export wait option

- images: add boot_modes (uefi, legacy) and tpm_mandatory.
- image/snapshot export tasks: add wait_for_completion.
- Bump the outscale provider constraint to ~> 1.8 (module and example).

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
## [1.0.0] - 2026-02-07
- Adds names to volumes and snapshots

Adds optional `name` attributes to volumes and snapshots, allowing users to specify names for these resources.

These names are then used in the `Name` tag applied to the resources.  If a name is not provided, a default name is generated using the project name, environment, and the key of the volume or snapshot.

Removes basic and complete examples, and also enables image capabilities in complete example.
- Adds region to provider and disables features

Adds the region configuration to the Outscale provider.

Comment out features to prevent issues in the example, likely related to missing configuration values.
Adds preconditions to ensure that the OSU API key variables are provided when the export task variables are used.
- Removes OOS (Object Storage) support

Removes the OOS (Object Storage) functionality from the module.

This simplifies the module to focus solely on BSU volumes, snapshots, and images, eliminating the need for the AWS provider and related configurations. A separate module is recommended for object storage management.
- Consolidates storage resource definitions

Refactors the module structure by merging volume, snapshot,
and image resource definitions into a single `main.tf` file.

This streamlines the module's organization and improves
maintainability by centralizing related resource configurations.
- Adds Outscale storage Terraform module

Implements a Terraform module for managing Outscale storage resources,
including BSU volumes, snapshots, images (OMI), and OOS (S3-compatible)
object storage.

Includes comprehensive documentation, examples, tests, and a standardized
directory structure based on agent-os specifications.
- Adds agent-os commands and Terraform standards

Adds commands for discovering, indexing, and injecting standards.

Adds Terraform-specific standards and general standards like code style, documentation, security, and versioning to the agent-os.
Also sets up a product documentation structure for mission, roadmap, and tech stack.

Introduces commands for planning a product and shaping a spec, integrating standards and best practices into the development workflow.
- Initial commit

