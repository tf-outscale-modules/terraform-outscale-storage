## MODIFIED Requirements
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
