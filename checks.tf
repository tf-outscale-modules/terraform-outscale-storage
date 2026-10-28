# The provider has no write-only argument for osu_api_key.secret_key: it lands in state (SECURITY.md).
check "osu_api_key_in_state" {
  assert {
    condition = !(
      (var.enable_image && length(var.image_export_tasks) > 0)
      || (var.enable_snapshot && length(var.snapshot_export_tasks) > 0)
    )
    error_message = "An export task is planned: the OSU API key secret_key is not write-only in the provider and lands in state. Use a dedicated least-privilege key and an encrypted, access-restricted backend (see SECURITY.md)."
  }
}
