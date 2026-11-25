# Security

## What lands in state

| Data | Where | Why | Mitigation |
|------|-------|-----|------------|
| `secret_key` of `snapshot_export_osu_api_key` and `image_export_osu_api_key` | `osu_export.osu_api_key` of `outscale_snapshot_export_task` and `outscale_image_export_task` | The provider (outscale 1.8) has no write-only (`*_wo`) argument for it, so the value is stored in state in plain text. The inputs are `sensitive` (redacted in plan and output) but cannot be `ephemeral` | See below; a `check` named `osu_api_key_in_state` warns on every plan that contains an export task |

Mitigation:

- Use a dedicated OSU API key, limited to the export bucket, never a general-purpose account key
- Rotate the key after the exports complete and remove the export tasks from the configuration
- Store state in an encrypted remote backend with restricted access; never commit `*.tfstate*`
- Supply the key through `TF_VAR_*` or CI secrets, never in `.tf` or `.tfvars` files

A future major release should switch to a write-only argument as soon as the provider offers one.

## Sharing and retained data

- **Public images**: `images[*].launch_permission.is_public = true` lets every Outscale account launch the OMI. It is opt-in, exclusive with `account_ids`, and reported by the `public_sharing` check on every plan. Share only images that hold no secret or proprietary content
- **Snapshots are shared with account IDs only**: there is no public option. The provider's `outscale_snapshot_attributes` never revokes access (its delete is a no-op and it does not read permissions back), so removing an account from `create_volume_permission` or destroying the resource leaves access in place. Revoke it manually (Outscale API `UpdateSnapshot` with a permission removal, or Cockpit) and verify with `ReadSnapshots`
- **Image permission changes**: every argument of `outscale_image_launch_permission` forces replacement; changing the account list unshares then re-shares the image, with a short unshared window
- **Termination snapshot**: `volumes[*].termination_snapshot_name` takes a snapshot of the volume before it is destroyed. It is not in state or managed by the module, keeps the volume data and incurs storage cost until it is deleted by hand; protect it like the volume

## Least privilege

Give the Outscale API credentials used by the provider only the permissions needed for the resource families you enable (volumes, snapshots, images). Sharing additionally needs the permission to update images and snapshots (`UpdateImage`, `UpdateSnapshot`).

## Reporting vulnerabilities

Report a vulnerability to the maintainers directly rather than in a public issue.
