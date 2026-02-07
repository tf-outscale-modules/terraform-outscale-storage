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
