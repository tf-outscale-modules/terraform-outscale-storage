# Shaping Notes: Remove OOS from Module

## Scope

Remove all OOS (Outscale Object Storage / S3-compatible) functionality from the outscale-storage module.

## Decisions

1. **OOS is out of scope** — Object storage has different lifecycle, access patterns, and provider requirements compared to block storage resources. A dedicated module would be more appropriate.
2. **Single provider** — Module simplifies to only `outscale/outscale`, eliminating the `hashicorp/aws` dependency.
3. **No migration path needed** — OOS support was added in the initial implementation and has not been released yet.

## What stays

- BSU Volumes (create, attach, configure)
- Snapshots (create, copy, export)
- Images/OMI (create, copy, export)
- All `enable_*` feature flags except `enable_oos`
- `_key` cross-referencing pattern
- Consistent tagging via `dynamic "tags"` blocks

## What is removed

- `oos.tf` — `aws_s3_bucket` and `aws_s3_object` resources
- `hashicorp/aws` provider dependency
- `enable_oos`, `oos_buckets`, `oos_objects` variables
- `oos_bucket_ids`, `oos_bucket_arns`, `oos_object_ids` outputs
- OOS test case and AWS provider in tests
- OOS sections in examples and documentation
