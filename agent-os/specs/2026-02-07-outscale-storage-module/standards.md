# Standards Summary

All standards are defined in `agent-os/standards/` and indexed in `agent-os/standards/index.yml`.

## Root Standards

1. **repo-structure** — Defines all repository configuration files (.gitignore, .editorconfig, .pre-commit-config.yaml, .tflint.hcl, .cliff.toml, mise.toml, LICENSE, README structure, GitLab CI)

## Global Standards

2. **code-style** — HCL formatting (terraform fmt, 2-space indent), block ordering (count/for_each first, tags last), expression preferences (for_each over count), comment guidelines
3. **documentation** — Module README requirements, terraform-docs auto-generation, variable description quality, copy-pasteable examples, CHANGELOG maintenance
4. **security** — Never commit secrets, encrypt state at rest, sensitive = true for secrets, least privilege IAM, default-deny network rules, static analysis in CI
5. **versioning** — Semantic versioning (major/minor/patch), vX.Y.Z git tags, ~> version constraints, pre-1.0 for unstable interfaces

## Terraform Standards

6. **module-structure** — Standard file layout (main.tf, variables.tf, outputs.tf, versions.tf, locals.tf, examples/, tests/), split main.tf if >200 lines
7. **naming** — snake_case for all identifiers, "this" for single instances, descriptive for multiple, common_tags pattern, {project}-{environment}-{purpose} resource naming
8. **outputs** — Output IDs/ARNs/endpoints, snake_case matching resource attributes, descriptions required, sensitive marking, grouped by resource
9. **providers** — Pessimistic version constraints (~>), no provider {} blocks in reusable modules, feature flags for optional features
10. **state** — Remote backends with locking, {project}/{environment}/{component}/terraform.tfstate key pattern, no backend config in reusable modules
11. **tech-stack** — Terraform/OpenTofu, per-project providers, native test framework, terraform-docs, per-project CI/CD
12. **variables** — snake_case, enable_/is_ boolean prefixes, description+type+default+validation, sensitive marking, required first then optional

## Testing Standards

13. **terraform-tests** — .tftest.hcl in tests/, plan and apply commands, test validations/resource counts/outputs/conditionals, terraform fmt/validate/test in CI
