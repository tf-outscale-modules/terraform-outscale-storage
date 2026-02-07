################################################################################
# Volumes
################################################################################

output "volume_ids" {
  description = "Map of volume keys to their IDs."
  value       = { for k, v in outscale_volume.this : k => v.volume_id }
}

output "volume_details" {
  description = "Map of volume keys to their details (id, size, type, iops, state, subregion)."
  value = {
    for k, v in outscale_volume.this : k => {
      volume_id      = v.volume_id
      size           = v.size
      volume_type    = v.volume_type
      iops           = v.iops
      state          = v.state
      subregion_name = v.subregion_name
    }
  }
}

output "volume_link_states" {
  description = "Map of volume link keys to their state."
  value       = { for k, v in outscale_volume_link.this : k => v.state }
}

################################################################################
# Snapshots
################################################################################

output "snapshot_ids" {
  description = "Map of snapshot keys to their IDs."
  value       = { for k, v in outscale_snapshot.this : k => v.snapshot_id }
}

output "snapshot_export_task_ids" {
  description = "Map of snapshot export task keys to their IDs."
  value       = { for k, v in outscale_snapshot_export_task.this : k => v.id }
}

################################################################################
# Images
################################################################################

output "image_ids" {
  description = "Map of image keys to their IDs."
  value       = { for k, v in outscale_image.this : k => v.image_id }
}

output "image_export_task_ids" {
  description = "Map of image export task keys to their IDs."
  value       = { for k, v in outscale_image_export_task.this : k => v.id }
}
