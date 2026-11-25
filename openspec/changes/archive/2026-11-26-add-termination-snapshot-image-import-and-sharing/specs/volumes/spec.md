# Spec Delta

## ADDED Requirements

### Requirement: Termination snapshot
A volume MAY set `termination_snapshot_name` (default `null`). When set, the module SHALL pass it to the provider so that a snapshot of the volume is taken before the volume is deleted; when `null`, nothing is sent and no snapshot is taken. The input description SHALL state that the snapshot is not managed by the module and outlives it.

#### Scenario: Termination snapshot requested
- **WHEN** `enable_volume = true` and a volume sets `termination_snapshot_name = "data-final"`
- **THEN** the plan creates the volume with that termination snapshot name

#### Scenario: Default creates no safety snapshot
- **WHEN** a volume does not set `termination_snapshot_name`
- **THEN** the volume is planned without a termination snapshot name and an existing configuration shows no diff

#### Scenario: Changing the name does not replace the volume
- **WHEN** `termination_snapshot_name` of an existing volume changes
- **THEN** the plan updates the volume in place and does not replace it
