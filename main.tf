################################################################################
# Images (OMI)
################################################################################

resource "outscale_image" "this" {
  for_each = var.enable_image ? var.images : {}

  image_name         = each.value.image_name
  description        = each.value.description
  vm_id              = each.value.vm_id
  source_image_id    = each.value.source_image_id
  source_region_name = each.value.source_region_name
  no_reboot          = each.value.no_reboot
  boot_modes         = each.value.boot_modes
  tpm_mandatory      = each.value.tpm_mandatory
  architecture       = each.value.architecture
  file_location      = each.value.file_location
  root_device_name   = each.value.root_device_name

  dynamic "block_device_mappings" {
    for_each = each.value.block_device_mappings

    content {
      device_name         = block_device_mappings.value.device_name
      virtual_device_name = block_device_mappings.value.virtual_device_name

      dynamic "bsu" {
        for_each = block_device_mappings.value.bsu != null ? [block_device_mappings.value.bsu] : []

        content {
          delete_on_vm_deletion = bsu.value.delete_on_vm_deletion
          iops                  = bsu.value.iops
          snapshot_id           = bsu.value.snapshot_id
          volume_size           = bsu.value.volume_size
          volume_type           = bsu.value.volume_type
        }
      }
    }
  }

  dynamic "tags" {
    for_each = merge(local.common_tags, { Name = each.value.image_name }, each.value.tags)

    content {
      key   = tags.key
      value = tags.value
    }
  }
}

################################################################################
# Image Launch Permissions
################################################################################

resource "outscale_image_launch_permission" "this" {
  for_each = local.image_launch_permissions

  image_id = outscale_image.this[each.key].image_id

  # Sorted and deduplicated so that reordering the list never replaces the resource (every argument is ForceNew).
  permission_additions {
    account_ids       = length(each.value.account_ids) > 0 ? sort(distinct(each.value.account_ids)) : null
    global_permission = each.value.is_public ? "true" : null
  }
}

################################################################################
# Image Export Tasks
################################################################################

resource "outscale_image_export_task" "this" {
  for_each = var.enable_image ? var.image_export_tasks : {}

  lifecycle {
    precondition {
      condition     = var.image_export_osu_api_key != null
      error_message = "image_export_osu_api_key must be provided when image_export_tasks is non-empty."
    }
  }

  image_id = (
    each.value.image_key != null
    ? outscale_image.this[each.value.image_key].image_id
    : each.value.image_id
  )
  wait_for_completion = each.value.wait_for_completion

  osu_export {
    disk_image_format = each.value.disk_image_format
    osu_bucket        = each.value.osu_bucket
    osu_prefix        = each.value.osu_prefix

    osu_api_key {
      api_key_id = var.image_export_osu_api_key.api_key_id
      secret_key = var.image_export_osu_api_key.secret_key
    }
  }

  dynamic "tags" {
    for_each = merge(
      local.common_tags,
      { Name = "${var.project_name}-${var.environment}-${each.key}" },
      each.value.tags,
    )

    content {
      key   = tags.key
      value = tags.value
    }
  }
}

################################################################################
# BSU Volumes
################################################################################

resource "outscale_volume" "this" {
  for_each = var.enable_volume ? var.volumes : {}

  subregion_name = each.value.subregion_name
  size           = each.value.size
  volume_type    = each.value.volume_type
  iops           = each.value.volume_type == "io1" ? each.value.iops : null
  snapshot_id    = each.value.snapshot_id

  termination_snapshot_name = each.value.termination_snapshot_name

  dynamic "tags" {
    for_each = merge(
      local.common_tags,
      { Name = coalesce(each.value.name, "${var.project_name}-${var.environment}-${each.key}") },
      each.value.tags,
    )

    content {
      key   = tags.key
      value = tags.value
    }
  }
}

################################################################################
# Volume Links (Attachments)
################################################################################

resource "outscale_volume_link" "this" {
  for_each = var.enable_volume ? var.volume_links : {}

  device_name = each.value.device_name
  vm_id       = each.value.vm_id
  volume_id = (
    each.value.volume_key != null
    ? outscale_volume.this[each.value.volume_key].volume_id
    : each.value.volume_id
  )
}

################################################################################
# Snapshots
################################################################################

resource "outscale_snapshot" "this" {
  for_each = var.enable_snapshot ? var.snapshots : {}

  description = each.value.description

  volume_id = (
    each.value.volume_key != null
    ? outscale_volume.this[each.value.volume_key].volume_id
    : each.value.volume_id
  )

  source_snapshot_id = each.value.source_snapshot_id
  source_region_name = each.value.source_region_name
  file_location      = each.value.file_location
  snapshot_size      = each.value.snapshot_size

  dynamic "tags" {
    for_each = merge(
      local.common_tags,
      { Name = coalesce(each.value.name, "${var.project_name}-${var.environment}-${each.key}") },
      each.value.tags,
    )

    content {
      key   = tags.key
      value = tags.value
    }
  }
}

################################################################################
# Snapshot Create-Volume Permissions
################################################################################

resource "outscale_snapshot_attributes" "this" {
  for_each = local.snapshot_create_volume_permissions

  snapshot_id = outscale_snapshot.this[each.key].snapshot_id

  # Sorted and deduplicated so that reordering the list never replaces the resource.
  # The provider never revokes access: removing an account is a manual action (SECURITY.md).
  permissions_to_create_volume_additions {
    account_ids = sort(distinct(each.value.account_ids))
  }
}

################################################################################
# Snapshot Export Tasks
################################################################################

resource "outscale_snapshot_export_task" "this" {
  for_each = var.enable_snapshot ? var.snapshot_export_tasks : {}

  lifecycle {
    precondition {
      condition     = var.snapshot_export_osu_api_key != null
      error_message = "snapshot_export_osu_api_key must be provided when snapshot_export_tasks is non-empty."
    }
  }

  snapshot_id = (
    each.value.snapshot_key != null
    ? outscale_snapshot.this[each.value.snapshot_key].snapshot_id
    : each.value.snapshot_id
  )
  wait_for_completion = each.value.wait_for_completion

  osu_export {
    disk_image_format = each.value.disk_image_format
    osu_bucket        = each.value.osu_bucket
    osu_prefix        = each.value.osu_prefix

    osu_api_key {
      api_key_id = var.snapshot_export_osu_api_key.api_key_id
      secret_key = var.snapshot_export_osu_api_key.secret_key
    }
  }

  dynamic "tags" {
    for_each = merge(
      local.common_tags,
      { Name = "${var.project_name}-${var.environment}-${each.key}" },
      each.value.tags,
    )

    content {
      key   = tags.key
      value = tags.value
    }
  }
}
