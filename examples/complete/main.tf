terraform {
  required_version = ">= 1.5"

  required_providers {
    outscale = {
      source  = "outscale/outscale"
      version = "~> 1.8"
    }
  }
}

# Outscale provider for BSU volumes, snapshots, and images
provider "outscale" {
  region = var.region
}

module "storage" {
  source = "../../"

  project_name = "my-project"
  environment  = "prod"

  tags = {
    Team       = "platform"
    CostCenter = "engineering"
  }

  ############################################################################
  # Volumes
  ############################################################################

  enable_volume = true

  volumes = {
    data = {
      subregion_name = "${var.region}a"
      size           = 100
      volume_type    = "io1"
      iops           = 3000

      # Snapshot taken before the volume is destroyed; it is not managed by the module and outlives it.
      termination_snapshot_name = "my-project-prod-data-final"
    }
    logs = {
      subregion_name = "${var.region}a"
      size           = 50
      volume_type    = "gp2"
      tags           = { Purpose = "logging" }
    }
    archive = {
      subregion_name = "${var.region}b"
      size           = 500
      volume_type    = "standard"
    }
  }

  # volume_links = {
  #   data_attach = {
  #     device_name = "/dev/sdb"
  #     vm_id       = var.vm_id
  #     volume_key  = "data"
  #   }
  #   logs_attach = {
  #     device_name = "/dev/sdc"
  #     vm_id       = var.vm_id
  #     volume_key  = "logs"
  #   }
  # }

  ############################################################################
  # Snapshots
  ############################################################################

  enable_snapshot = true

  snapshots = {
    data_backup = {
      volume_key  = "data"
      description = "Daily backup of data volume"

      # Accounts only (never public). Revoking access is manual: the provider does not revoke it.
      create_volume_permission = length(var.snapshot_share_account_ids) > 0 ? {
        account_ids = var.snapshot_share_account_ids
      } : null
    }
    logs_backup = {
      volume_key  = "logs"
      description = "Weekly backup of logs volume"
    }
    # external_copy = {
    #   source_snapshot_id = var.source_snapshot_id
    #   source_region_name = var.region
    #   description        = "Copy of an external snapshot"
    # }
  }

  # snapshot_export_tasks = {
  #   data_export = {
  #     snapshot_key      = "data_backup"
  #     disk_image_format = "qcow2"
  #     osu_bucket        = "my-project-prod-exports"
  #     osu_prefix        = "snapshots/"
  #   }
  # }

  # snapshot_export_osu_api_key = {
  #   api_key_id = var.osu_api_key_id
  #   secret_key = var.osu_secret_key
  # }

  ############################################################################
  # Images (OMI)
  ############################################################################

  # enable_image = true

  # images = {
  #   base = {
  #     image_name  = "my-project-prod-base"
  #     description = "Base image from running VM"
  #     vm_id       = var.vm_id
  #     no_reboot   = true
  #   }
  #   registered = {
  #     image_name       = "my-project-prod-registered"
  #     description      = "OMI registered from a snapshot"
  #     architecture     = "x86_64"
  #     root_device_name = "/dev/sda1"
  #     block_device_mappings = [
  #       {
  #         device_name = "/dev/sda1"
  #         bsu         = { snapshot_id = var.root_snapshot_id }
  #       }
  #     ]
  #   }
  #   imported = {
  #     image_name    = "my-project-prod-imported"
  #     file_location = var.manifest_url # pre-signed URL of the OMI manifest
  #   }
  #   shared = {
  #     image_name  = "my-project-prod-shared"
  #     vm_id       = var.vm_id
  #     # account_ids xor is_public; is_public = true triggers check.public_sharing
  #     launch_permission = { account_ids = var.image_share_account_ids }
  #   }
  #   custom = {
  #     image_name  = "my-project-prod-custom"
  #     description = "Custom image with block device mappings"
  #     vm_id       = var.vm_id
  #     no_reboot   = true
  #     block_device_mappings = [
  #       {
  #         device_name = "/dev/sda1"
  #         bsu = {
  #           volume_size           = 50
  #           volume_type           = "gp2"
  #           delete_on_vm_deletion = true
  #         }
  #       },
  #       {
  #         device_name = "/dev/sdb"
  #         bsu = {
  #           volume_size = 100
  #           volume_type = "io1"
  #           iops        = 3000
  #         }
  #       }
  #     ]
  #   }
  # }

  # image_export_tasks = {
  #   base_export = {
  #     image_key         = "base"
  #     disk_image_format = "raw"
  #     osu_bucket        = "my-project-prod-exports"
  #     osu_prefix        = "images/"
  #   }
  # }

  # image_export_osu_api_key = {
  #   api_key_id = var.osu_api_key_id
  #   secret_key = var.osu_secret_key
  # }

}
