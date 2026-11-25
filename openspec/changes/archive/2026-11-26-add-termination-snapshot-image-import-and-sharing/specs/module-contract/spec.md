# Spec Delta

## ADDED Requirements

### Requirement: Public sharing warning
Making an image public is legal but exposes the OMI to every account. A `check` named `public_sharing` SHALL warn whenever a created image sets `launch_permission.is_public = true`, and `SECURITY.md` SHALL document public image sharing, the manual revocation of snapshot access and the retained termination snapshot.

#### Scenario: Public image planned
- **WHEN** `enable_image = true` and an image sets `launch_permission = { is_public = true }`
- **THEN** the plan emits a warning from `check.public_sharing`

#### Scenario: Account sharing only
- **WHEN** images and snapshots share only with `account_ids`
- **THEN** `check.public_sharing` emits no warning
