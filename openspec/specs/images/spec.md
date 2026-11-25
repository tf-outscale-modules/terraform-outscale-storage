# images Specification

## Purpose
Images (OMI) the module creates or copies, their export tasks to an OOS bucket, validation and outputs.

## Requirements

### Requirement: Images from the images map
When `enable_image` is `true`, the module SHALL create one image (OMI) per entry of `images`, keyed by the map key, named `image_name`. The source SHALL be the VM `vm_id` (with optional `no_reboot`), the image `source_image_id` (with optional `source_region_name`), the manifest `file_location`, or `block_device_mappings` together with `root_device_name`; an entry with none of them SHALL be rejected.

#### Scenario: Image from a VM
- **WHEN** `enable_image = true` and an image sets `image_name = "golden"` and `vm_id = "i-12345678"`
- **THEN** the plan creates one image named `golden`

#### Scenario: Image without source
- **WHEN** an image sets none of `vm_id`, `source_image_id`, `file_location` or `block_device_mappings` with `root_device_name`
- **THEN** the plan fails with "Each image must specify one of: vm_id, source_image_id, file_location, or block_device_mappings with root_device_name."

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

### Requirement: Image registration options
An image MAY set `architecture`, `file_location` and `root_device_name` (all default `null`, sent to the provider only when set). `architecture` SHALL be one of `i386` or `x86_64`. `file_location` is the pre-signed URL of an OMI manifest to import; `block_device_mappings` with `root_device_name` registers an OMI from a snapshot. The input description SHALL state that these three are create-time settings.

#### Scenario: Register from a snapshot
- **WHEN** an image sets `block_device_mappings` with a `bsu.snapshot_id`, `root_device_name = "/dev/sda1"` and `architecture = "x86_64"`
- **THEN** the plan creates one image with those arguments

#### Scenario: Import from a manifest
- **WHEN** an image sets `file_location = "https://bucket.example/omi.manifest.xml"`
- **THEN** the plan creates one image with that file location and no `vm_id` or `source_image_id`

#### Scenario: Unknown architecture
- **WHEN** an image sets `architecture = "arm64"`
- **THEN** the plan fails with "Image architecture must be one of: i386, x86_64."

### Requirement: Image launch permission
An image MAY set `launch_permission = { account_ids, is_public }` (default `null`; `account_ids` defaults to `[]`, `is_public` to `false`). When `enable_image` is `true`, the module SHALL create one launch permission per image that sets it, keyed like the image, granting launch rights to the listed accounts, or to everyone when `is_public` is `true`. The order and duplicates of `account_ids` SHALL NOT change the plan.

#### Scenario: Share with accounts
- **WHEN** an image sets `launch_permission = { account_ids = ["123456789012"] }`
- **THEN** the plan creates one launch permission for that image and account

#### Scenario: No sharing by default
- **WHEN** no image sets `launch_permission`
- **THEN** no launch permission is planned

#### Scenario: Reordered account IDs
- **WHEN** `account_ids` is reordered or gains a duplicate with the same set of accounts
- **THEN** the plan shows no change

### Requirement: Image launch permission validation
Each `account_ids` entry SHALL be a 12-digit account ID, and a `launch_permission` SHALL name at least one account or set `is_public = true`, never both.

#### Scenario: Malformed account ID
- **WHEN** `launch_permission = { account_ids = ["abc"] }`
- **THEN** the plan fails with "Image launch_permission account_ids must be 12-digit account IDs."

#### Scenario: Empty permission
- **WHEN** `launch_permission = {}`
- **THEN** the plan fails with "Image launch_permission must set account_ids or is_public = true, not both and not neither."

#### Scenario: Public and accounts together
- **WHEN** `launch_permission = { account_ids = ["123456789012"], is_public = true }`
- **THEN** the plan fails with the same message
