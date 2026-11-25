# Tasks

Standards to fetch before editing HCL: `terraform-code-style`, `terraform-variables`, `terraform-outputs`, `terraform-security`, `terraform-versioning`.

## 1. Volume termination snapshot

- [x] 1.1 Add `termination_snapshot_name = optional(string)` to `volumes` in `variables.tf` (description says the snapshot is unmanaged and outlives the module) and pass it in `outscale_volume.this` in `main.tf`; verify `tofu validate` passes.
- [x] 1.2 Add a `tests/main.tftest.hcl` run asserting the value is planned when set and `null` when unset; verify `tofu test` passes.
- [x] 1.3 Set it on one volume in `examples/complete/main.tf`; verify `tofu init -backend=false && tofu validate` in examples/complete passes (no `test:examples` mise task exists in this repo).

## 2. Image registration

- [x] 2.1 Add `architecture`, `file_location`, `root_device_name` (`optional(string)`) to `images` and pass them in `outscale_image.this`; add the `architecture` validation ("Image architecture must be one of: i386, x86_64.") and widen the source validation with the new message from the images spec; grep the repo for the old message and update it.
- [x] 2.2 Add runs for: register from snapshot, import from `file_location`, unknown architecture rejected, no source rejected; verify `tofu test` passes.
- [x] 2.3 Add a registration image to `examples/complete/main.tf` (commented placeholders for IDs/URL where a real value is required); verify `tofu init -backend=false && tofu validate` in examples/complete passes (no `test:examples` mise task exists in this repo).

## 3. Image launch permission

- [x] 3.1 Add `launch_permission` to `images` with the two validations (12-digit IDs, accounts xor `is_public`); add a local of images that set it (respecting `enable_image`) and `outscale_image_launch_permission.this` with `dynamic` `permission_additions` (`sort(distinct(account_ids))`, `global_permission = "true"` only when public); verify `tofu validate` passes.
- [x] 3.2 Add runs: accounts share planned, none by default, reordered/duplicate IDs give an identical planned list, malformed ID rejected, empty and both-set rejected; verify `tofu test` passes.
- [x] 3.3 Share one example image with an account ID variable in `examples/complete`; verify `tofu init -backend=false && tofu validate` in examples/complete passes (no `test:examples` mise task exists in this repo).

## 4. Snapshot create-volume permission

- [x] 4.1 Add `create_volume_permission = optional(object({ account_ids = list(string) }))` to `snapshots` with the validations (non-empty, 12-digit IDs) and `outscale_snapshot_attributes.this` (`permissions_to_create_volume_additions` with `sort(distinct(account_ids))`); the description states that revoking access is manual because the provider's delete is a no-op.
- [x] 4.2 Add runs: share planned, none by default, reordered/duplicate IDs identical, malformed ID rejected, empty list rejected; verify `tofu test` passes.
- [x] 4.3 Share one example snapshot in `examples/complete`; verify `tofu init -backend=false && tofu validate` in examples/complete passes (no `test:examples` mise task exists in this repo).

## 5. Public sharing guardrail and docs

- [x] 5.1 Add `check "public_sharing"` to `checks.tf` (images only, respecting `enable_image`); add a run with `expect_failures = [check.public_sharing]` for a public image, and a run proving no warning for account-only sharing of images and snapshots; verify `tofu test` passes.
- [x] 5.2 Update `SECURITY.md` (public image sharing, snapshot access revoked manually, retained termination snapshot, least privilege for the extra API calls) and the README security notes by hand outside the `BEGIN_TF_DOCS` block; verify the text matches the module-contract delta.

## 6. Verification and commit

- [x] 6.1 Run `tofu fmt -recursive`, `tofu init -backend=false && tofu validate`, `tflint --recursive`, `tofu test`, `tofu validate` in examples/complete (no `test:examples` mise task exists), `mise run spec-validate`; verify all exit 0 and report output as-is.
- [x] 6.2 Run `pre-commit run -a` (terraform-docs regenerates the README tables); verify it passes on the second run and the second plan of the example is empty by inspection of the inputs (no computed value is sent).
- [ ] 6.3 Commit with the subject `Add volume termination snapshot, image import and image/snapshot sharing` (minor; reads as the CHANGELOG line; no breaking note needed, mention the reworded image source validation message in the body).

## Workflow follow-up

- Archive the change after review (`/openspec-archive-change`); the commit subject must still read as the CHANGELOG line, and `mise run changelog` runs at release.
