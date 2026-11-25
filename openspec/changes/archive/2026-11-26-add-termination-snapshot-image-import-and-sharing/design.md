# Design

## Context

`main.tf` creates `outscale_image.this`, `outscale_volume.this` and `outscale_snapshot.this` with `for_each` over map inputs gated by `enable_*`. Provider `outscale/outscale ~> 1.8` stays; schemas checked in 1.8.0 (all arguments below present) and 1.9.0 (unchanged). Standards applied: `terraform-versioning` (minor), `terraform-variables` (optional attributes default `null`, `is_` boolean prefix, validation with accepted values), `terraform-security` (dangerous-but-legal → `check`), `terraform-code-style` (no perpetual diff, `for_each`, no `try()` to hide inputs), `quality-simplicity` (no output, no extra flag).

## Goals / Non-Goals

**Goals:** expose the four provider features opt-in, with an empty second plan and no change for existing callers.

**Non-Goals:** revoking permissions (`permission_removals` / `permissions_to_create_volume_removals`; snapshot access is revoked manually), public snapshots, managing the termination snapshot in state, new outputs, a provider floor change, sharing of resources the module does not create.

## Decisions

1. **Volume**: `termination_snapshot_name` → `outscale_volume.termination_snapshot_name` (framework resource, optional, no `RequiresReplace`, not read back). Adding, changing or removing it is an in-place update with no API effect until destroy. Alternative: a separate `outscale_snapshot` before destroy — rejected, not expressible in Terraform ordering.
2. **Image registration**: `architecture`, `file_location`, `root_device_name` → same-named `outscale_image` arguments (optional + computed). Sent as `null` when unset, so existing plans are untouched. The source validation gains `file_location` and `block_device_mappings` + `root_device_name`; the `images` input shape is otherwise unchanged (additive attributes). Alternative: separate `image_imports` map — rejected, it duplicates `images` and its tags/export wiring.
3. **Sharing as per-entry objects**, not new maps: `images[*].launch_permission` = `optional(object({ account_ids = optional(list(string), []), is_public = optional(bool, false) }))` and `snapshots[*].create_volume_permission` = `optional(object({ account_ids = list(string) }))` (accounts only, user decision: no public snapshots). The permission resource reuses the image/snapshot key (`outscale_image_launch_permission.this[key]`, `outscale_snapshot_attributes.this[key]`), so there is no `*_key`/`*_id` cross-reference to validate and no sharing of external resources (Non-Goal). A local filters entries that set the object and respects `enable_image` / `enable_snapshot`.
4. **Arguments sent**: `permission_additions` (images) / `permissions_to_create_volume_additions` (snapshots) only. `account_ids = sort(distinct(...))`, omitted when empty. For images `global_permission` is the **string** `"true"`, emitted only when `is_public`; snapshots never send `global_permission`. The addition block is a `dynamic` block, absent when there is nothing to send. Validation (12-digit IDs via `can(regex("^[0-9]{12}$", id))`; images: exactly one of accounts / public; snapshots: at least one account) lives in `variables.tf` with messages naming the accepted values.
5. **Public sharing (images only)**: `is_public` defaults to `false`, is rejected together with `account_ids`, and triggers `check "public_sharing"` (warning on every plan, like `osu_api_key_in_state`). Alternative: a validation error — rejected, public OMIs are a legitimate use. `SECURITY.md` gets a section for it. Snapshots have no public option, so no check applies to them.

## Replacement impact and perpetual diff

| Argument / resource | Provider behaviour (1.8.0) | Effect on existing state | Perpetual-diff handling |
|---|---|---|---|
| `outscale_volume.termination_snapshot_name` | optional, no replace, copied from plan, not read back | none when `null`; in-place update when changed | none needed |
| `outscale_image.architecture`, `root_device_name` | optional+computed, **not** ForceNew; Update handles tags only | none when `null` | read back from the server; setting the server value (`x86_64`, `/dev/sda1`) is stable. A later change shows a diff the provider cannot apply → documented as create-time; change means a manual replace |
| `outscale_image.file_location` | same | none when `null` | see Open Questions |
| `outscale_image_launch_permission` | every argument ForceNew; read fills computed `permissions_to_launch`, not the config blocks; delete reverses the additions | new resource only | `sort(distinct())` keeps list order from causing a replacement; account list change = destroy (unshare) then create (share), a short unshared window; no `create_before_destroy` (it would remove accounts kept in both lists) |
| `outscale_snapshot_attributes` | additions block `RequiresReplace`; **delete is a no-op and read ignores permissions** | new resource only | same `sort(distinct())`; no drift detection; revocation is manual |

Existing state migrates with no `moved` block: no resource address changes.

## Risks / Trade-offs

- [Snapshot permissions are never revoked by the provider: removing an account or destroying the resource leaves access] → input description, `SECURITY.md`, README note; revocation is a manual action outside the module (Non-Goal).
- [Termination snapshot outlives the volume, costs storage, holds the data] → description and `SECURITY.md`; live test (provider 1.9.0): the snapshot is created on destroy with the description "Snapshot created by Terraform before deletion of Volume: <id>" and a `Name` tag whose value is the name wrapped in literal double quotes (provider quirk); the name used is the one in state at destroy time, so an in-place change before destroy is honoured. Delete it by hand (or import + destroy).
- [Public image sharing exposes the OMI to all accounts] → opt-in, exclusive with accounts, `check.public_sharing` warning.
- [Image permission replacement unshares briefly] → documented; account changes are rare.
- [Image validation message changes] → only the wording; accepted inputs widen.

## Migration Plan

Minor release; consumers bump the tag. No state change until an attribute is set. Rollback: unset the attributes (volume: in place; images: destroy of the permission resource unshares; snapshot attributes: destroy leaves access in place).

## Open Questions

- Whether the provider reads `file_location` back identically to the pre-signed URL. If not, an imported image shows a diff on every plan; confirm on a real account at the first use and, if it differs, document it and stop sending the value after create.
