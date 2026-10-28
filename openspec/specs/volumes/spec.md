# volumes Specification

## Purpose
BSU volumes the module creates, their attachments to VMs, validation and outputs.

## Requirements

### Requirement: Volumes from the volumes map
When `enable_volume` is `true`, the module SHALL create one BSU volume per entry of `volumes`, keyed by the map key, in `subregion_name` with the given `size`. `volume_type` SHALL default to `standard`, and `iops` SHALL be sent only when `volume_type` is `io1`. `snapshot_id` optionally creates the volume from a snapshot. The volume SHALL carry a `Name` tag equal to `name` when set, otherwise `<project_name>-<environment>-<key>`.

#### Scenario: Default volume
- **WHEN** `enable_volume = true` and a volume sets only `subregion_name = "eu-west-2a"` and `size = 10`
- **THEN** the plan creates one `standard` volume named `<project_name>-<environment>-<key>`

#### Scenario: io1 volume
- **WHEN** a volume sets `volume_type = "io1"` and `iops = 3000`
- **THEN** the volume is planned with 3000 IOPS

#### Scenario: IOPS ignored for other types
- **WHEN** a volume sets `volume_type = "gp2"` and `iops = 3000`
- **THEN** the volume is planned without IOPS

### Requirement: Volume validation
A volume `volume_type` SHALL be one of `standard`, `gp2` or `io1`; `iops` SHALL be set when the type is `io1`; `size` SHALL be between 1 and 14901.

#### Scenario: Unknown type
- **WHEN** a volume has `volume_type = "ssd"`
- **THEN** the plan fails with "Volume type must be one of: standard, gp2, io1."

#### Scenario: io1 without IOPS
- **WHEN** a volume has `volume_type = "io1"` and no `iops`
- **THEN** the plan fails with "IOPS must be specified when volume_type is io1."

#### Scenario: Size out of range
- **WHEN** a volume has `size = 0` or `size = 14902`
- **THEN** the plan fails with "Volume size must be between 1 and 14901 GB."

### Requirement: Volume links
When `enable_volume` is `true`, the module SHALL attach a volume to a VM for each entry of `volume_links`, at `device_name` on `vm_id`. The volume SHALL be the module volume selected by `volume_key`, or the external volume `volume_id` when `volume_key` is not set. The attribute `tags` of a link is deprecated and ignored (a volume link has no tags); the input description SHALL say so.

#### Scenario: Link to a module volume
- **WHEN** a link sets `volume_key = "data"`, `vm_id` and `device_name` and `volumes` has the key `data`
- **THEN** the plan attaches that volume to the VM

#### Scenario: Link to an external volume
- **WHEN** a link sets `volume_id = "vol-12345678"` and no `volume_key`
- **THEN** the plan attaches that external volume to the VM

#### Scenario: No volume reference
- **WHEN** a link sets neither `volume_key` nor `volume_id`
- **THEN** the plan fails with "Each volume link must specify either volume_key or volume_id."

### Requirement: Volume outputs
The module SHALL expose `volume_ids` (volume key to volume ID), `volume_details` (volume key to an object with `volume_id`, `size`, `volume_type`, `iops`, `state` and `subregion_name`) and `volume_link_states` (link key to its state).

#### Scenario: Volume ID
- **WHEN** a volume `data` is created
- **THEN** `volume_ids["data"]` is its volume ID
