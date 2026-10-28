# images Specification

## Purpose
Images (OMI) the module creates or copies, their export tasks to an OOS bucket, validation and outputs.

## Requirements

### Requirement: Images from the images map
When `enable_image` is `true`, the module SHALL create one image (OMI) per entry of `images`, keyed by the map key, named `image_name`. The source SHALL be the VM `vm_id` (with optional `no_reboot`) or the image `source_image_id` (with optional `source_region_name`); an entry with neither SHALL be rejected.

#### Scenario: Image from a VM
- **WHEN** `enable_image = true` and an image sets `image_name = "golden"` and `vm_id = "i-12345678"`
- **THEN** the plan creates one image named `golden`

#### Scenario: Image without source
- **WHEN** an image sets neither `vm_id` nor `source_image_id`
- **THEN** the plan fails with "Each image must specify either vm_id or source_image_id."

### Requirement: Image options
`description`, `boot_modes`, `tpm_mandatory` and `block_device_mappings` SHALL be optional and passed to the provider. A block device mapping has an optional `device_name`, `virtual_device_name` and an optional `bsu` object (`delete_on_vm_deletion`, `iops`, `snapshot_id`, `volume_size`, `volume_type`); `block_device_mappings` defaults to `[]`.

#### Scenario: Boot modes and vTPM
- **WHEN** an image sets `boot_modes = ["uefi"]` and `tpm_mandatory = true`
- **THEN** the image is planned with those settings

#### Scenario: Block device mapping
- **WHEN** an image has a block device mapping with a `bsu` object of `volume_size = 50`
- **THEN** the image is planned with one block device mapping holding a BSU of that size

### Requirement: Image boot modes validation
Image `boot_modes` SHALL contain only `uefi` or `legacy`.

#### Scenario: Unknown boot mode
- **WHEN** an image sets `boot_modes = ["bios"]`
- **THEN** the plan fails with "Image boot_modes must contain only: uefi, legacy."

### Requirement: Image export tasks
When `enable_image` is `true`, the module SHALL create one export task per entry of `image_export_tasks`, exporting the module image selected by `image_key`, or the external image `image_id` when `image_key` is not set, to the `osu_bucket` under the optional `osu_prefix`, in `disk_image_format`. `wait_for_completion` SHALL be passed to the provider (the provider default applies when unset). The OSU access is given by `image_export_osu_api_key`.

#### Scenario: Export of a module image
- **WHEN** a task sets `image_key = "golden"`, `disk_image_format = "raw"` and `osu_bucket = "exports"`, and `image_export_osu_api_key` is set
- **THEN** the plan creates an export task of the image `golden` to the bucket `exports`

### Requirement: Image export validation
Each export task SHALL specify `image_key` or `image_id`, `disk_image_format` SHALL be one of `qcow2`, `raw` or `vmdk`, and `image_export_osu_api_key` SHALL be set whenever the module creates an image export task.

#### Scenario: No image reference
- **WHEN** a task sets neither `image_key` nor `image_id`
- **THEN** the plan fails with "Each image export task must specify either image_key or image_id."

#### Scenario: Unknown disk format
- **WHEN** a task sets `disk_image_format = "iso"`
- **THEN** the plan fails with "Disk image format must be one of: qcow2, raw, vmdk."

#### Scenario: Missing API key
- **WHEN** `enable_image = true`, `image_export_tasks` has one entry and `image_export_osu_api_key` is `null`
- **THEN** the plan fails with "image_export_osu_api_key must be provided when image_export_tasks is non-empty."

### Requirement: Image outputs
The module SHALL expose `image_ids` (image key to image ID) and `image_export_task_ids` (task key to task ID).

#### Scenario: Image ID
- **WHEN** an image `golden` is created
- **THEN** `image_ids["golden"]` is its image ID
