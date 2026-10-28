## Decisions
- **Secret in state**: `outscale_*_export_task.osu_export.osu_api_key.secret_key` has no write-only variant in provider 1.8 (schema checked with `tofu providers schema -json`), so it cannot be kept out of state. `check "osu_api_key_in_state"` (`checks.tf`) asserts that no export task is planned (`var.enable_image` and non-empty `image_export_tasks`, `var.enable_snapshot` and non-empty `snapshot_export_tasks`); it emits a warning, never an error. No resource change, no perpetual diff.
- **Tags** (`locals.tf`): `merge(var.tags, { Project, Environment, ManagedBy })`. Images: `merge(common_tags, { Name = image_name }, tags)`. Export tasks: `Name = "${project_name}-${environment}-${key}"` in the same position as for volumes. Provider tags are applied in place; no replacement.
- **Image source validation** (variable validation, single-variable, valid on 1.5): `v.vm_id != null || v.source_image_id != null`.
- **project_name validation**: `length(trimspace(var.project_name)) > 0 && length(var.project_name) <= 100`.
- **volume_links.tags**: description only; type unchanged.
- No address change, no `moved`, no state migration. `versions.tf` untouched.
