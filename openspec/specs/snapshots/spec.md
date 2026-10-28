# snapshots Specification

## Purpose
Snapshots the module creates or copies, their export tasks to an OOS bucket, validation and outputs.

## Requirements

### Requirement: Snapshots from the snapshots map
When `enable_snapshot` is `true`, the module SHALL create one snapshot per entry of `snapshots`, keyed by the map key. The source SHALL be the module volume selected by `volume_key`, or the external volume `volume_id` when `volume_key` is not set. The snapshot SHALL carry a `Name` tag equal to `name` when set, otherwise `<project_name>-<environment>-<key>`; `description` is optional.

#### Scenario: Snapshot of a module volume
- **WHEN** `enable_volume` and `enable_snapshot` are `true` and a snapshot sets `volume_key = "data"`
- **THEN** the plan creates a snapshot of the volume `data`

#### Scenario: Copy of an existing snapshot
- **WHEN** a snapshot sets `source_snapshot_id = "snap-12345678"` and `source_region_name = "eu-west-2"`
- **THEN** the plan creates a snapshot copied from that snapshot

### Requirement: Snapshot copy and import
`source_snapshot_id` and `source_region_name` SHALL be passed to the provider to copy an existing snapshot, and `file_location` and `snapshot_size` to import one from a bucket.

#### Scenario: Import from a bucket
- **WHEN** a snapshot sets `file_location` and `snapshot_size`
- **THEN** the plan creates a snapshot with those arguments

### Requirement: Snapshot source validation
Each snapshot SHALL specify at least one of `volume_key`, `volume_id`, `source_snapshot_id` or `file_location`.

#### Scenario: No source
- **WHEN** a snapshot sets only `description`
- **THEN** the plan fails with "Each snapshot must specify one of: volume_key, volume_id, source_snapshot_id, or file_location."

### Requirement: Snapshot export tasks
When `enable_snapshot` is `true`, the module SHALL create one export task per entry of `snapshot_export_tasks`, exporting the module snapshot selected by `snapshot_key`, or the external snapshot `snapshot_id` when `snapshot_key` is not set, to the `osu_bucket` under the optional `osu_prefix`, in `disk_image_format`. The OSU access is given by `snapshot_export_osu_api_key`.

#### Scenario: Export of a module snapshot
- **WHEN** a task sets `snapshot_key = "daily"`, `disk_image_format = "qcow2"` and `osu_bucket = "exports"`, and `snapshot_export_osu_api_key` is set
- **THEN** the plan creates an export task of the snapshot `daily` to the bucket `exports`

#### Scenario: Export without wait
- **WHEN** a task sets `wait_for_completion = false` (when unset, the provider default applies)
- **THEN** the task is planned with `wait_for_completion = false`

### Requirement: Snapshot export validation
Each export task SHALL specify `snapshot_key` or `snapshot_id`, `disk_image_format` SHALL be one of `qcow2`, `raw` or `vmdk`, and `snapshot_export_osu_api_key` SHALL be set whenever the module creates a snapshot export task.

#### Scenario: No snapshot reference
- **WHEN** a task sets neither `snapshot_key` nor `snapshot_id`
- **THEN** the plan fails with "Each snapshot export task must specify either snapshot_key or snapshot_id."

#### Scenario: Unknown disk format
- **WHEN** a task sets `disk_image_format = "iso"`
- **THEN** the plan fails with "Disk image format must be one of: qcow2, raw, vmdk."

#### Scenario: Missing API key
- **WHEN** `enable_snapshot = true`, `snapshot_export_tasks` has one entry and `snapshot_export_osu_api_key` is `null`
- **THEN** the plan fails with "snapshot_export_osu_api_key must be provided when snapshot_export_tasks is non-empty."

### Requirement: Snapshot outputs
The module SHALL expose `snapshot_ids` (snapshot key to snapshot ID) and `snapshot_export_task_ids` (task key to task ID).

#### Scenario: Snapshot ID
- **WHEN** a snapshot `daily` is created
- **THEN** `snapshot_ids["daily"]` is its snapshot ID
