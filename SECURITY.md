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

## Least privilege

Give the Outscale API credentials used by the provider only the permissions needed for the resource families you enable (volumes, snapshots, images).

## Reporting vulnerabilities

Report a vulnerability to the maintainers directly rather than in a public issue.
