# Spec Delta

## ADDED Requirements

### Requirement: Snapshot create-volume permission
A snapshot MAY set `create_volume_permission = { account_ids }` (default `null`; accounts only, no public option). When `enable_snapshot` is `true`, the module SHALL create one attributes resource per snapshot that sets it, keyed like the snapshot, allowing the listed accounts to create volumes from it. The order and duplicates of `account_ids` SHALL NOT change the plan.

#### Scenario: Share with accounts
- **WHEN** a snapshot sets `create_volume_permission = { account_ids = ["123456789012"] }`
- **THEN** the plan creates one attributes resource for that snapshot and account

#### Scenario: No sharing by default
- **WHEN** no snapshot sets `create_volume_permission`
- **THEN** no attributes resource is planned

#### Scenario: Reordered account IDs
- **WHEN** `account_ids` is reordered or gains a duplicate with the same set of accounts
- **THEN** the plan shows no change

### Requirement: Snapshot create-volume permission validation
`account_ids` SHALL hold at least one entry and each entry SHALL be a 12-digit account ID.

#### Scenario: Malformed account ID
- **WHEN** `create_volume_permission = { account_ids = ["abc"] }`
- **THEN** the plan fails with "Snapshot create_volume_permission account_ids must hold at least one 12-digit account ID."

#### Scenario: Empty list
- **WHEN** `create_volume_permission = { account_ids = [] }`
- **THEN** the plan fails with the same message

### Requirement: Snapshot permission revocation is manual
Removing an account or destroying the module-managed resource SHALL NOT be relied on to revoke access already granted (the provider's delete is a no-op); the `create_volume_permission` input description and `SECURITY.md` SHALL say revocation is manual.

#### Scenario: Description documents manual revocation
- **WHEN** the generated README documents `snapshots`
- **THEN** its description says revoking access is manual
