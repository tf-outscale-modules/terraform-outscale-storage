# Plan: Remove OOS (Object Storage) from Outscale Storage Module

## Context

The module currently includes OOS (Outscale Object Storage) support via the `hashicorp/aws` provider with S3-compatible endpoints. The decision is to remove OOS entirely and make it out of scope for this module. This simplifies the module to a single provider (`outscale/outscale`) covering only BSU volumes, snapshots, and images.

## Changes

1. Delete `oos.tf`
2. Remove AWS provider from `versions.tf`
3. Remove OOS variables (`enable_oos`, `oos_buckets`, `oos_objects`) from `variables.tf`
4. Remove OOS outputs (`oos_bucket_ids`, `oos_bucket_arns`, `oos_object_ids`) from `outputs.tf`
5. Remove OOS-related test cases and AWS provider from `tests/main.tftest.hcl`
6. Remove OOS from `examples/basic/` and `examples/complete/`
7. Update `README.md` to remove OOS references
8. Update `agent-os/` docs (roadmap, shape, references)

## Verification

1. `tofu fmt -check -recursive`
2. `tofu init -backend=false && tofu validate`
3. `tofu test` — expect 6 tests passing (down from 7)
