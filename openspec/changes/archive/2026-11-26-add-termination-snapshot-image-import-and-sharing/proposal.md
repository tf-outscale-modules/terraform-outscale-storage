# Proposal

## Why

The module cannot yet use four features the Outscale provider already ships in 1.8.0: a safety snapshot taken when a volume is destroyed, registration of an OMI from a snapshot or an imported manifest, and sharing of images and snapshots with other accounts. Consumers work around them with out-of-module resources, which breaks the "one call manages storage" contract. Everything exists in the pinned `~> 1.8` provider, so no floor change is needed.

## What Changes

- `volumes[*].termination_snapshot_name` (opt-in): snapshot the volume before it is deleted.
- `images[*].architecture`, `file_location`, `root_device_name` (opt-in): register an OMI from a snapshot (`block_device_mappings` + `root_device_name`, optional `architecture`) or import it from a pre-signed manifest URL (`file_location`). The "image has a source" validation accepts these two new sources; its error message changes accordingly.
- `images[*].launch_permission` (opt-in object `{ account_ids, is_public }`): creates one `outscale_image_launch_permission` per image that sets it.
- `snapshots[*].create_volume_permission` (opt-in object `{ account_ids }`, accounts only, at least one 12-digit ID): creates one `outscale_snapshot_attributes` per snapshot that sets it. Public snapshots are deliberately not offered.
- Making an image public (`launch_permission.is_public = true`) is explicit, cannot be combined with account IDs, and is reported by a new `check "public_sharing"` warning on every plan.
- `SECURITY.md` documents public image sharing, the manual revocation of snapshot access (the provider's delete is a no-op) and the retained termination snapshot; the README security notes follow.
- No new output, no new provider requirement, no `moved` block.

Semver: **minor** (`terraform-versioning`: new optional attributes with `null` defaults, new resources). No existing input or output changes type, default or meaning; with the new attributes unset the plan is unchanged and the second plan is empty. The one visible difference is the wording of the image-source validation message. Nothing secret-bearing is added: account IDs and flags are not secrets, so no `*_wo` argument applies (`terraform-security`), and nothing new lands in state beyond the resource attributes.

## Capabilities

### New Capabilities

None; the four existing capability directories cover the change.

### Modified Capabilities

- `volumes`: ADDED requirement for the termination snapshot.
- `images`: MODIFIED "Images from the images map" (two new sources, new message); ADDED requirements for registration options and validation, and for launch permissions.
- `snapshots`: ADDED requirements for accounts-only create-volume permissions and their validation.
- `module-contract`: ADDED requirement for the image-only `public_sharing` check.

## Impact

- Code: `variables.tf` (three objects extended, two new nested objects, validations), `main.tf` (two new resources, three new arguments on existing ones), `checks.tf` (one check), `locals.tf` only if a sorted-ID local is needed.
- Docs/tests: `tests/main.tftest.hcl`, `examples/complete`, `SECURITY.md`, README (terraform-docs block regenerated, security notes by hand).
- Provider: unchanged `~> 1.8`; arguments verified in 1.8.0 (and unchanged in 1.9.0).
- State: two new resource types; no secret.
