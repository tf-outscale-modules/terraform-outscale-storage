variable "region" {
  description = "Outscale region."
  type        = string
  default     = "eu-west-2"
}

variable "vm_id" {
  description = "ID of the VM to attach volumes to and create images from."
  type        = string
}

variable "source_snapshot_id" {
  description = "ID of an external snapshot to copy."
  type        = string
}

variable "osu_api_key_id" {
  description = "OSU API key ID for export tasks."
  type        = string
  sensitive   = true
}

variable "osu_secret_key" {
  description = "OSU secret key for export tasks."
  type        = string
  sensitive   = true
}
