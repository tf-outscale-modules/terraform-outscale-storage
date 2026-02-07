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
