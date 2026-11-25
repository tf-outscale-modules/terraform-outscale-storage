locals {
  common_tags = merge(
    var.tags,
    {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
    },
  )
}

locals {
  image_launch_permissions = var.enable_image ? {
    for k, v in var.images : k => v.launch_permission if v.launch_permission != null
  } : {}

  snapshot_create_volume_permissions = var.enable_snapshot ? {
    for k, v in var.snapshots : k => v.create_volume_permission if v.create_volume_permission != null
  } : {}
}
