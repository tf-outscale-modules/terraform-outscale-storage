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
