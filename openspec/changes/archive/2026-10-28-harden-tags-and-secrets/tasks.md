## 1. Code
- [x] 1.1 Tag precedence and `Name` tags for images and export tasks
- [x] 1.2 Validations: image source, `project_name`; `volume_links.tags` description
- [x] 1.3 `checks.tf` with `osu_api_key_in_state`; `SECURITY.md`
## 2. Tests, docs, examples
- [x] 2.1 Tests in `tests/main.tftest.hcl` (mock provider)
- [x] 2.2 README (CHANGELOG link, tofu commands, Security section), `examples/complete`
## 3. Verify
- [x] 3.1 `tofu fmt -recursive`, `tofu validate`, `tflint --recursive`, `tofu test`, `pre-commit run -a`
