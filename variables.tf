################################################################################
# Feature Flags
################################################################################

variable "enable_volume" {
  description = "Enable BSU volume resources."
  type        = bool
  default     = false
}

variable "enable_snapshot" {
  description = "Enable snapshot resources."
  type        = bool
  default     = false
}

variable "enable_image" {
  description = "Enable image (OMI) resources."
  type        = bool
  default     = false
}

variable "enable_oos" {
  description = "Enable OOS (S3-compatible object storage) resources."
  type        = bool
  default     = false
}

################################################################################
# Common
################################################################################

variable "project_name" {
  description = "Name of the project. Used in resource naming and tagging."
  type        = string
}

variable "environment" {
  description = "Deployment environment. Valid values: dev, staging, prod."
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "tags" {
  description = "Additional tags to apply to all resources. Merged with common tags (Project, Environment, ManagedBy)."
  type        = map(string)
  default     = {}
}

################################################################################
# Volumes
################################################################################

variable "volumes" {
  description = "Map of BSU volumes to create. Each key is a logical name used for cross-referencing."
  type = map(object({
    subregion_name = string
    size           = number
    volume_type    = optional(string, "standard")
    iops           = optional(number)
    snapshot_id    = optional(string)
    tags           = optional(map(string), {})
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.volumes : contains(["standard", "gp2", "io1"], v.volume_type)
    ])
    error_message = "Volume type must be one of: standard, gp2, io1."
  }

  validation {
    condition = alltrue([
      for k, v in var.volumes : v.volume_type != "io1" || v.iops != null
    ])
    error_message = "IOPS must be specified when volume_type is io1."
  }

  validation {
    condition = alltrue([
      for k, v in var.volumes : v.size >= 1 && v.size <= 14901
    ])
    error_message = "Volume size must be between 1 and 14901 GB."
  }
}

variable "volume_links" {
  description = "Map of volume-to-VM attachments. Use volume_key to reference a volume from the volumes map, or volume_id for an external volume."
  type = map(object({
    device_name = string
    vm_id       = string
    volume_key  = optional(string)
    volume_id   = optional(string)
    tags        = optional(map(string), {})
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.volume_links : v.volume_key != null || v.volume_id != null
    ])
    error_message = "Each volume link must specify either volume_key or volume_id."
  }
}

################################################################################
# Snapshots
################################################################################

variable "snapshots" {
  description = "Map of snapshots to create. Use volume_key to reference a volume from the volumes map, or volume_id for an external volume. Set source_snapshot_id to copy an existing snapshot."
  type = map(object({
    description        = optional(string)
    volume_key         = optional(string)
    volume_id          = optional(string)
    source_snapshot_id = optional(string)
    source_region_name = optional(string)
    file_location      = optional(string)
    snapshot_size      = optional(number)
    tags               = optional(map(string), {})
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.snapshots : (
        v.volume_key != null || v.volume_id != null || v.source_snapshot_id != null || v.file_location != null
      )
    ])
    error_message = "Each snapshot must specify one of: volume_key, volume_id, source_snapshot_id, or file_location."
  }
}

variable "snapshot_export_tasks" {
  description = "Map of snapshot export tasks. Use snapshot_key to reference a snapshot from the snapshots map, or snapshot_id for an external snapshot."
  type = map(object({
    snapshot_key      = optional(string)
    snapshot_id       = optional(string)
    disk_image_format = string
    osu_bucket        = string
    osu_prefix        = optional(string)
    tags              = optional(map(string), {})
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.snapshot_export_tasks : v.snapshot_key != null || v.snapshot_id != null
    ])
    error_message = "Each snapshot export task must specify either snapshot_key or snapshot_id."
  }

  validation {
    condition = alltrue([
      for k, v in var.snapshot_export_tasks : contains(["qcow2", "raw", "vmdk"], v.disk_image_format)
    ])
    error_message = "Disk image format must be one of: qcow2, raw, vmdk."
  }
}

variable "snapshot_export_osu_api_key" {
  description = "OSU API key for snapshot export tasks. Required when snapshot_export_tasks is non-empty."
  type = object({
    api_key_id = string
    secret_key = string
  })
  default   = null
  sensitive = true
}

################################################################################
# Images
################################################################################

variable "images" {
  description = "Map of images (OMI) to create. Specify vm_id to create from a running VM, or source_image_id to copy an existing image."
  type = map(object({
    image_name         = string
    description        = optional(string)
    vm_id              = optional(string)
    source_image_id    = optional(string)
    source_region_name = optional(string)
    no_reboot          = optional(bool)
    block_device_mappings = optional(list(object({
      device_name         = optional(string)
      virtual_device_name = optional(string)
      bsu = optional(object({
        delete_on_vm_deletion = optional(bool)
        iops                  = optional(number)
        snapshot_id           = optional(string)
        volume_size           = optional(number)
        volume_type           = optional(string)
      }))
    })), [])
    tags = optional(map(string), {})
  }))
  default = {}
}

variable "image_export_tasks" {
  description = "Map of image export tasks. Use image_key to reference an image from the images map, or image_id for an external image."
  type = map(object({
    image_key         = optional(string)
    image_id          = optional(string)
    disk_image_format = string
    osu_bucket        = string
    osu_prefix        = optional(string)
    tags              = optional(map(string), {})
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.image_export_tasks : v.image_key != null || v.image_id != null
    ])
    error_message = "Each image export task must specify either image_key or image_id."
  }

  validation {
    condition = alltrue([
      for k, v in var.image_export_tasks : contains(["qcow2", "raw", "vmdk"], v.disk_image_format)
    ])
    error_message = "Disk image format must be one of: qcow2, raw, vmdk."
  }
}

variable "image_export_osu_api_key" {
  description = "OSU API key for image export tasks. Required when image_export_tasks is non-empty."
  type = object({
    api_key_id = string
    secret_key = string
  })
  default   = null
  sensitive = true
}

################################################################################
# OOS (Object Storage)
################################################################################

variable "oos_buckets" {
  description = "Map of OOS (S3-compatible) buckets to create."
  type = map(object({
    bucket        = string
    force_destroy = optional(bool, false)
    tags          = optional(map(string), {})
  }))
  default = {}
}

variable "oos_objects" {
  description = "Map of OOS objects to create. Use bucket_key to reference a bucket from the oos_buckets map, or bucket for an external bucket name."
  type = map(object({
    bucket_key = optional(string)
    bucket     = optional(string)
    key        = string
    source     = optional(string)
    content    = optional(string)
    tags       = optional(map(string), {})
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.oos_objects : v.bucket_key != null || v.bucket != null
    ])
    error_message = "Each OOS object must specify either bucket_key or bucket."
  }
}
