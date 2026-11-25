# Spec Delta

## ADDED Requirements

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

## MODIFIED Requirements

### Requirement: Images from the images map
When `enable_image` is `true`, the module SHALL create one image (OMI) per entry of `images`, keyed by the map key, named `image_name`. The source SHALL be the VM `vm_id` (with optional `no_reboot`), the image `source_image_id` (with optional `source_region_name`), the manifest `file_location`, or `block_device_mappings` together with `root_device_name`; an entry with none of them SHALL be rejected.

#### Scenario: Image from a VM
- **WHEN** `enable_image = true` and an image sets `image_name = "golden"` and `vm_id = "i-12345678"`
- **THEN** the plan creates one image named `golden`

#### Scenario: Image without source
- **WHEN** an image sets none of `vm_id`, `source_image_id`, `file_location` or `block_device_mappings` with `root_device_name`
- **THEN** the plan fails with "Each image must specify one of: vm_id, source_image_id, file_location, or block_device_mappings with root_device_name."
