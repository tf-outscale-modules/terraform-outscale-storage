output "volume_ids" {
  description = "Created volume IDs."
  value       = module.storage.volume_ids
}

output "volume_details" {
  description = "Created volume details."
  value       = module.storage.volume_details
}

output "volume_link_states" {
  description = "Volume attachment states."
  value       = module.storage.volume_link_states
}

output "snapshot_ids" {
  description = "Created snapshot IDs."
  value       = module.storage.snapshot_ids
}

output "snapshot_export_task_ids" {
  description = "Snapshot export task IDs."
  value       = module.storage.snapshot_export_task_ids
}

output "image_ids" {
  description = "Created image IDs."
  value       = module.storage.image_ids
}

output "image_export_task_ids" {
  description = "Image export task IDs."
  value       = module.storage.image_export_task_ids
}
