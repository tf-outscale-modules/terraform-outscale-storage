variable "access_key_id" {
  description = "Outscale access key ID."
  type        = string
  sensitive   = true
}

variable "secret_key_id" {
  description = "Outscale secret key ID."
  type        = string
  sensitive   = true
}

variable "region" {
  description = "Outscale region."
  type        = string
  default     = "eu-west-2"
}
