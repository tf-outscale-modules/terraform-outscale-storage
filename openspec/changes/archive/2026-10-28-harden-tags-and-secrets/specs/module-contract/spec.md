## MODIFIED Requirements
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


## ADDED Requirements
### Requirement: Name tag
Volumes, snapshots, images and export tasks SHALL carry a `Name` tag, which per-resource `tags` can override: the `name` or the generated `<project_name>-<environment>-<key>` for volumes and snapshots, the generated name for export tasks, the `image_name` for images.

#### Scenario: Name tag on an image and an export task
- **WHEN** an image sets `image_name = "golden"` and an export task has the key `base_export` with `project_name = "demo"` and `environment = "dev"`
- **THEN** the image carries `Name = "golden"` and the export task carries `Name = "demo-dev-base_export"`

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
