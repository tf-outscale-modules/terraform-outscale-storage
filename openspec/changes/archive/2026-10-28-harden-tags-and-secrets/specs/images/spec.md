## MODIFIED Requirements
### Requirement: Images from the images map
When `enable_image` is `true`, the module SHALL create one image (OMI) per entry of `images`, keyed by the map key, named `image_name`. The source SHALL be the VM `vm_id` (with optional `no_reboot`) or the image `source_image_id` (with optional `source_region_name`); an entry with neither SHALL be rejected.

#### Scenario: Image from a VM
- **WHEN** `enable_image = true` and an image sets `image_name = "golden"` and `vm_id = "i-12345678"`
- **THEN** the plan creates one image named `golden`

#### Scenario: Image without source
- **WHEN** an image sets neither `vm_id` nor `source_image_id`
- **THEN** the plan fails with "Each image must specify either vm_id or source_image_id."
