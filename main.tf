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
    for_each = merge(local.common_tags, each.value.tags)

    content {
      key   = tags.key
      value = tags.value
    }
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
    for_each = merge(local.common_tags, each.value.tags)

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

  dynamic "tags" {
    for_each = merge(local.common_tags, each.value.tags)

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
    for_each = merge(local.common_tags, each.value.tags)

    content {
      key   = tags.key
      value = tags.value
    }
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
    for_each = merge(local.common_tags, each.value.tags)

    content {
      key   = tags.key
      value = tags.value
    }
  }
}
