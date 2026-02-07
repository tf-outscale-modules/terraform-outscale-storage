output "volume_ids" {
  description = "Created volume IDs."
  value       = module.storage.volume_ids
}

output "snapshot_ids" {
  description = "Created snapshot IDs."
  value       = module.storage.snapshot_ids
}
