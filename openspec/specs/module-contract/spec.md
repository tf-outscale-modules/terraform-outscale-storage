# module-contract Specification

## Purpose
Toolchain and provider constraints, input and output set, feature flags, validation and common tags of the module as a whole.

## Requirements

### Requirement: Tooling and provider constraints
The module SHALL declare `required_version = ">= 1.5"` and the `outscale/outscale` provider with version constraint `~> 1.8` in `versions.tf`.

#### Scenario: Supported toolchain
- **WHEN** the module is used with OpenTofu or Terraform 1.5 or later and an `outscale/outscale` provider 1.8.x or later 1.x
- **THEN** initialization and planning succeed

#### Scenario: Older toolchain
- **WHEN** the module is used with a Terraform or OpenTofu version older than 1.5
- **THEN** initialization fails on the `required_version` constraint

### Requirement: No provider or backend configuration
The module SHALL NOT contain `provider` or `backend` blocks; the caller configures the Outscale provider and the state backend.

#### Scenario: Caller configures the provider
- **WHEN** the module is called from a root module that configures the `outscale` provider
- **THEN** every resource of the module uses that configuration

### Requirement: Input set
The module SHALL expose these inputs: `project_name` (`string`, required), `environment` (`string`, required), `tags` (`map(string)`, default `{}`), the feature flags `enable_volume`, `enable_snapshot` and `enable_image` (`bool`, default `false`) and the maps `volumes`, `volume_links`, `snapshots`, `snapshot_export_tasks`, `images` and `image_export_tasks` (default `{}`). The map keys SHALL be logical identifiers used for cross references and as output keys.

#### Scenario: Required inputs only
- **WHEN** only `project_name` and `environment` are set
- **THEN** the plan creates no resource

#### Scenario: Missing environment
- **WHEN** `environment` is not set
- **THEN** the plan fails because the required variable has no value

### Requirement: Sensitive API key inputs
The inputs `snapshot_export_osu_api_key` and `image_export_osu_api_key` SHALL be objects with `api_key_id` and `secret_key`, default `null`, and marked `sensitive`.

#### Scenario: Key not printed
- **WHEN** `snapshot_export_osu_api_key` is set
- **THEN** its value is redacted in plan output

### Requirement: Feature flags
Each resource family SHALL be created only when its flag is `true`, whatever its map contains: `enable_volume` for `volumes` and `volume_links`, `enable_snapshot` for `snapshots` and `snapshot_export_tasks`, `enable_image` for `images` and `image_export_tasks`.

#### Scenario: Entries ignored while the flag is off
- **WHEN** `volumes` has one entry and `enable_volume` is `false`
- **THEN** the plan creates no volume

#### Scenario: Entries created when the flag is on
- **WHEN** `volumes` has one entry and `enable_volume = true`
- **THEN** the plan creates one volume

### Requirement: Environment validation
`environment` SHALL be one of `dev`, `staging` or `prod`.

#### Scenario: Unknown environment
- **WHEN** `environment = "qa"`
- **THEN** the plan fails with "Environment must be one of: dev, staging, prod."

### Requirement: Common tags
Every volume, snapshot, image and export task SHALL carry the tags `Project` (from `project_name`), `Environment` and `ManagedBy = "terraform"`, merged with `var.tags`. On a key conflict the three default tags win over `var.tags`. Per-resource `tags` SHALL win over the common tags.

#### Scenario: Default tags
- **WHEN** `project_name = "demo"`, `environment = "dev"` and a volume is created
- **THEN** the volume carries `Project = "demo"`, `Environment = "dev"` and `ManagedBy = "terraform"`

#### Scenario: Extra tags
- **WHEN** `tags = { CostCenter = "infra" }`
- **THEN** every created resource also carries `CostCenter = "infra"`

#### Scenario: Caller tries to override a module tag
- **WHEN** `tags = { ManagedBy = "manual" }`
- **THEN** every created resource carries `ManagedBy = "terraform"`

#### Scenario: Per-resource tag wins
- **WHEN** `tags = { Team = "a" }` and a volume sets `tags = { Team = "b" }`
- **THEN** that volume carries `Team = "b"`


### Requirement: Name tag
Volumes, snapshots, images and export tasks SHALL carry a `Name` tag, which per-resource `tags` can override: the `name` or the generated `<project_name>-<environment>-<key>` for volumes and snapshots, the generated name for export tasks, the `image_name` for images.

#### Scenario: Name tag on an image and an export task
- **WHEN** an image sets `image_name = "golden"` and an export task has the key `base_export` with `project_name = "demo"` and `environment = "dev"`
- **THEN** the image carries `Name = "golden"` and the export task carries `Name = "demo-dev-base_export"`

### Requirement: Output set
The module SHALL expose these outputs: `volume_ids`, `volume_details`, `volume_link_states`, `snapshot_ids`, `snapshot_export_task_ids`, `image_ids` and `image_export_task_ids`. Each SHALL be a map keyed by the logical key of its input map, and empty when its family is not created. No output SHALL be sensitive.

#### Scenario: Nothing enabled
- **WHEN** no feature flag is set
- **THEN** every output is an empty map

### Requirement: Project name validation
`project_name` SHALL NOT be blank and SHALL be at most 100 characters.

#### Scenario: Blank project name
- **WHEN** `project_name = " "`
- **THEN** the plan fails with "project_name must not be blank and must be at most 100 characters."

### Requirement: Export API key in state
The OSU API key given to an export task reaches the provider in a plain argument, so its `secret_key` lands in state. A `check` named `osu_api_key_in_state` SHALL warn whenever an image or snapshot export task is planned, and `SECURITY.md` SHALL document what lands in state and its mitigation.

#### Scenario: Export task planned
- **WHEN** `enable_snapshot = true` and `snapshot_export_tasks` has one entry
- **THEN** the plan emits a warning from `check.osu_api_key_in_state`

#### Scenario: No export task
- **WHEN** `snapshot_export_tasks` and `image_export_tasks` are empty
- **THEN** no warning is emitted
