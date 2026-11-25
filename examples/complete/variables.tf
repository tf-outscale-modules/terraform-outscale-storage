variable "region" {
  description = "Outscale region."
  type        = string
  default     = "eu-west-2"
}

variable "snapshot_share_account_ids" {
  description = "12-digit Outscale account IDs allowed to create volumes from the data_backup snapshot. Empty (default) shares nothing."
  type        = list(string)
  default     = []
}
