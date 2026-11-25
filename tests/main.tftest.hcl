################################################################################
# Mocked provider for tests (no Outscale account needed)
################################################################################

mock_provider "outscale" {}

################################################################################
# Test: defaults create nothing
################################################################################

run "defaults_create_nothing" {
  command = plan

  variables {
    project_name = "test-project"
    environment  = "dev"
  }

  assert {
    condition     = length(keys(outscale_volume.this)) == 0
    error_message = "No volumes should be created when enable_volume is false."
  }

  assert {
    condition     = length(keys(outscale_snapshot.this)) == 0
    error_message = "No snapshots should be created when enable_snapshot is false."
  }

  assert {
    condition     = length(keys(outscale_image.this)) == 0
    error_message = "No images should be created when enable_image is false."
  }

}

################################################################################
# Test: volume creation
################################################################################

run "volume_creation" {
  command = plan

  variables {
    project_name  = "test-project"
    environment   = "dev"
    enable_volume = true
    volumes = {
      data = {
        subregion_name = "eu-west-2a"
        size           = 50
        volume_type    = "gp2"
      }
    }
  }

  assert {
    condition     = length(keys(outscale_volume.this)) == 1
    error_message = "Expected one volume to be planned."
  }
}

################################################################################
# Test: invalid volume type rejected
################################################################################

run "invalid_volume_type_rejected" {
  command = plan

  variables {
    project_name  = "test-project"
    environment   = "dev"
    enable_volume = true
    volumes = {
      bad = {
        subregion_name = "eu-west-2a"
        size           = 50
        volume_type    = "ssd"
      }
    }
  }

  expect_failures = [var.volumes]
}

################################################################################
# Test: io1 requires iops
################################################################################

run "io1_requires_iops" {
  command = plan

  variables {
    project_name  = "test-project"
    environment   = "dev"
    enable_volume = true
    volumes = {
      fast = {
        subregion_name = "eu-west-2a"
        size           = 100
        volume_type    = "io1"
      }
    }
  }

  expect_failures = [var.volumes]
}

################################################################################
# Test: invalid environment rejected
################################################################################

run "invalid_environment_rejected" {
  command = plan

  variables {
    project_name = "test-project"
    environment  = "qa"
  }

  expect_failures = [var.environment]
}

################################################################################
# Test: invalid disk format rejected
################################################################################

run "invalid_disk_format_rejected" {
  command = plan

  variables {
    project_name    = "test-project"
    environment     = "dev"
    enable_snapshot = true
    snapshots = {
      test = {
        volume_id   = "vol-12345678"
        description = "test snapshot"
      }
    }
    snapshot_export_tasks = {
      export = {
        snapshot_key      = "test"
        disk_image_format = "vhd"
        osu_bucket        = "my-bucket"
      }
    }
    snapshot_export_osu_api_key = {
      api_key_id = "test-key"
      secret_key = "test-secret"
    }
  }

  expect_failures = [var.snapshot_export_tasks]
}

################################################################################
# Test: image boot modes and vTPM
################################################################################

run "image_boot_modes_and_tpm" {
  command = plan

  variables {
    project_name = "test-project"
    environment  = "dev"
    enable_image = true
    images = {
      golden = {
        image_name    = "golden"
        vm_id         = "i-12345678"
        boot_modes    = ["uefi"]
        tpm_mandatory = true
      }
    }
  }

  assert {
    condition     = outscale_image.this["golden"].tpm_mandatory == true && outscale_image.this["golden"].boot_modes == toset(["uefi"])
    error_message = "boot_modes/tpm_mandatory not passed through"
  }
}

run "invalid_boot_mode_rejected" {
  command = plan

  variables {
    project_name = "test-project"
    environment  = "dev"
    enable_image = true
    images = {
      golden = {
        image_name = "golden"
        vm_id      = "i-12345678"
        boot_modes = ["bios"]
      }
    }
  }

  expect_failures = [var.images]
}

################################################################################
# Test: tags_cannot_override_module_tags
################################################################################

run "tags_cannot_override_module_tags" {
  command = plan

  variables {
    project_name  = "demo"
    environment   = "dev"
    enable_volume = true
    tags = {
      ManagedBy   = "manual"
      Project     = "other"
      Environment = "other"
      Team        = "a"
    }
    volumes = {
      data = {
        subregion_name = "eu-west-2a"
        size           = 10
      }
    }
  }

  assert {
    condition = alltrue([
      for t in outscale_volume.this["data"].tags :
      t.key != "ManagedBy" || t.value == "terraform"
      ]) && alltrue([
      for t in outscale_volume.this["data"].tags :
      t.key != "Project" || t.value == "demo"
      ]) && alltrue([
      for t in outscale_volume.this["data"].tags :
      t.key != "Environment" || t.value == "dev"
    ])
    error_message = "var.tags must not override Project, Environment or ManagedBy."
  }

  assert {
    condition     = contains([for t in outscale_volume.this["data"].tags : t.key], "Team")
    error_message = "Extra tags must still be applied."
  }
}

################################################################################
# Test: image and export task Name tags
################################################################################

run "image_and_export_task_name_tags" {
  command = plan

  variables {
    project_name = "demo"
    environment  = "dev"
    enable_image = true
    images = {
      base = {
        image_name = "golden"
        vm_id      = "i-12345678"
      }
    }
    image_export_tasks = {
      base_export = {
        image_key         = "base"
        disk_image_format = "raw"
        osu_bucket        = "exports"
      }
    }
    image_export_osu_api_key = {
      api_key_id = "id"
      secret_key = "secret"
    }
  }

  # The export task triggers the secret-in-state warning, which the test expects.
  expect_failures = [check.osu_api_key_in_state]

  assert {
    condition     = contains([for t in outscale_image.this["base"].tags : "${t.key}=${t.value}"], "Name=golden")
    error_message = "Image must carry Name = image_name."
  }

  assert {
    condition     = contains([for t in outscale_image_export_task.this["base_export"].tags : "${t.key}=${t.value}"], "Name=demo-dev-base_export")
    error_message = "Export task must carry a generated Name tag."
  }
}

################################################################################
# Test: image without source rejected
################################################################################

run "image_without_source_rejected" {
  command = plan

  variables {
    project_name = "demo"
    environment  = "dev"
    enable_image = true
    images = {
      base = {
        image_name = "golden"
      }
    }
  }

  expect_failures = [var.images]
}

################################################################################
# Test: image from source image accepted
################################################################################

run "image_from_source_image_accepted" {
  command = plan

  variables {
    project_name = "demo"
    environment  = "dev"
    enable_image = true
    images = {
      copy = {
        image_name      = "copy"
        source_image_id = "ami-12345678"
      }
    }
  }

  assert {
    condition     = length(outscale_image.this) == 1
    error_message = "An image with source_image_id must be planned."
  }
}

################################################################################
# Test: blank project_name rejected
################################################################################

run "blank_project_name_rejected" {
  command = plan

  variables {
    project_name = " "
    environment  = "dev"
  }

  expect_failures = [var.project_name]
}

################################################################################
# Test: overlong project_name rejected
################################################################################

run "long_project_name_rejected" {
  command = plan

  variables {
    project_name = join("", [for i in range(101) : "a"])
    environment  = "dev"
  }

  expect_failures = [var.project_name]
}

################################################################################
# Test: export task warns about key in state
################################################################################

run "export_task_warns_secret_in_state" {
  command = plan

  variables {
    project_name    = "demo"
    environment     = "dev"
    enable_snapshot = true
    snapshot_export_tasks = {
      export = {
        snapshot_id       = "snap-12345678"
        disk_image_format = "qcow2"
        osu_bucket        = "exports"
      }
    }
    snapshot_export_osu_api_key = {
      api_key_id = "id"
      secret_key = "secret"
    }
  }

  expect_failures = [check.osu_api_key_in_state]
}

################################################################################
# Test: no export task, no warning
################################################################################

run "no_export_task_no_warning" {
  command = plan

  variables {
    project_name    = "demo"
    environment     = "dev"
    enable_snapshot = true
    snapshots = {
      data = {
        volume_id = "vol-12345678"
      }
    }
  }

  assert {
    condition     = length(outscale_snapshot_export_task.this) == 0
    error_message = "No export task expected."
  }
}

################################################################################
# Test: volume termination snapshot
################################################################################

run "volume_termination_snapshot" {
  command = plan

  variables {
    project_name  = "demo"
    environment   = "dev"
    enable_volume = true
    volumes = {
      data = {
        subregion_name            = "eu-west-2a"
        size                      = 10
        termination_snapshot_name = "data-final"
      }
      plain = {
        subregion_name = "eu-west-2a"
        size           = 10
      }
    }
  }

  assert {
    condition     = outscale_volume.this["data"].termination_snapshot_name == "data-final"
    error_message = "termination_snapshot_name must be passed when set."
  }

  assert {
    condition     = outscale_volume.this["plain"].termination_snapshot_name == null
    error_message = "termination_snapshot_name must be null by default."
  }
}

################################################################################
# Test: image registration (snapshot, manifest import)
################################################################################

run "image_registration_options" {
  command = plan

  variables {
    project_name = "demo"
    environment  = "dev"
    enable_image = true
    images = {
      from_snapshot = {
        image_name       = "from-snapshot"
        architecture     = "x86_64"
        root_device_name = "/dev/sda1"
        block_device_mappings = [{
          device_name = "/dev/sda1"
          bsu         = { snapshot_id = "snap-12345678" }
        }]
      }
      imported = {
        image_name    = "imported"
        file_location = "https://bucket.example/omi.manifest.xml"
      }
    }
  }

  assert {
    condition = (
      outscale_image.this["from_snapshot"].architecture == "x86_64"
      && outscale_image.this["from_snapshot"].root_device_name == "/dev/sda1"
    )
    error_message = "architecture and root_device_name must be passed."
  }

  assert {
    condition     = outscale_image.this["imported"].file_location == "https://bucket.example/omi.manifest.xml"
    error_message = "file_location must be passed."
  }
}

run "invalid_architecture_rejected" {
  command = plan

  variables {
    project_name = "demo"
    environment  = "dev"
    enable_image = true
    images = {
      bad = {
        image_name   = "bad"
        vm_id        = "i-12345678"
        architecture = "arm64"
      }
    }
  }

  expect_failures = [var.images]
}

run "image_block_devices_without_root_device_rejected" {
  command = plan

  variables {
    project_name = "demo"
    environment  = "dev"
    enable_image = true
    images = {
      bad = {
        image_name = "bad"
        block_device_mappings = [{
          device_name = "/dev/sda1"
          bsu         = { snapshot_id = "snap-12345678" }
        }]
      }
    }
  }

  expect_failures = [var.images]
}

################################################################################
# Test: image launch permission
################################################################################

run "image_launch_permission_accounts" {
  command = plan

  variables {
    project_name = "demo"
    environment  = "dev"
    enable_image = true
    images = {
      shared = {
        image_name = "shared"
        vm_id      = "i-12345678"
        launch_permission = {
          account_ids = ["222222222222", "111111111111", "222222222222"]
        }
      }
      private = {
        image_name = "private"
        vm_id      = "i-12345678"
      }
    }
  }

  assert {
    condition     = length(outscale_image_launch_permission.this) == 1 && contains(keys(outscale_image_launch_permission.this), "shared")
    error_message = "Only the image that sets launch_permission gets a permission."
  }

  assert {
    condition     = join(",", outscale_image_launch_permission.this["shared"].permission_additions[0].account_ids) == "111111111111,222222222222"
    error_message = "account_ids must be sorted and deduplicated."
  }

  assert {
    condition     = outscale_image_launch_permission.this["shared"].permission_additions[0].global_permission == null
    error_message = "global_permission must not be sent for account sharing."
  }
}

run "image_launch_permission_ignored_when_disabled" {
  command = plan

  variables {
    project_name = "demo"
    environment  = "dev"
    images = {
      shared = {
        image_name        = "shared"
        vm_id             = "i-12345678"
        launch_permission = { account_ids = ["111111111111"] }
      }
    }
  }

  assert {
    condition     = length(outscale_image_launch_permission.this) == 0
    error_message = "No permission expected while enable_image is false."
  }
}

run "image_launch_permission_public_warns" {
  command = plan

  variables {
    project_name = "demo"
    environment  = "dev"
    enable_image = true
    images = {
      shared = {
        image_name        = "shared"
        vm_id             = "i-12345678"
        launch_permission = { is_public = true }
      }
    }
  }

  expect_failures = [check.public_sharing]

  assert {
    condition     = outscale_image_launch_permission.this["shared"].permission_additions[0].global_permission == "true"
    error_message = "Public sharing must send global_permission = true."
  }
}

run "image_launch_permission_bad_account_rejected" {
  command = plan

  variables {
    project_name = "demo"
    environment  = "dev"
    enable_image = true
    images = {
      shared = {
        image_name        = "shared"
        vm_id             = "i-12345678"
        launch_permission = { account_ids = ["abc"] }
      }
    }
  }

  expect_failures = [var.images]
}

run "image_launch_permission_empty_rejected" {
  command = plan

  variables {
    project_name = "demo"
    environment  = "dev"
    enable_image = true
    images = {
      shared = {
        image_name        = "shared"
        vm_id             = "i-12345678"
        launch_permission = {}
      }
    }
  }

  expect_failures = [var.images]
}

run "image_launch_permission_public_and_accounts_rejected" {
  command = plan

  variables {
    project_name = "demo"
    environment  = "dev"
    enable_image = true
    images = {
      shared = {
        image_name        = "shared"
        vm_id             = "i-12345678"
        launch_permission = { account_ids = ["111111111111"], is_public = true }
      }
    }
  }

  expect_failures = [var.images]
}

################################################################################
# Test: snapshot create-volume permission
################################################################################

run "snapshot_create_volume_permission" {
  command = plan

  variables {
    project_name    = "demo"
    environment     = "dev"
    enable_snapshot = true
    snapshots = {
      shared = {
        volume_id = "vol-12345678"
        create_volume_permission = {
          account_ids = ["222222222222", "111111111111", "111111111111"]
        }
      }
      private = {
        volume_id = "vol-12345678"
      }
    }
  }

  assert {
    condition     = length(outscale_snapshot_attributes.this) == 1 && contains(keys(outscale_snapshot_attributes.this), "shared")
    error_message = "Only the snapshot that sets create_volume_permission gets attributes."
  }

  assert {
    condition     = join(",", outscale_snapshot_attributes.this["shared"].permissions_to_create_volume_additions[0].account_ids) == "111111111111,222222222222"
    error_message = "account_ids must be sorted and deduplicated."
  }
}

run "snapshot_create_volume_permission_bad_account_rejected" {
  command = plan

  variables {
    project_name    = "demo"
    environment     = "dev"
    enable_snapshot = true
    snapshots = {
      shared = {
        volume_id                = "vol-12345678"
        create_volume_permission = { account_ids = ["abc"] }
      }
    }
  }

  expect_failures = [var.snapshots]
}

run "snapshot_create_volume_permission_empty_rejected" {
  command = plan

  variables {
    project_name    = "demo"
    environment     = "dev"
    enable_snapshot = true
    snapshots = {
      shared = {
        volume_id                = "vol-12345678"
        create_volume_permission = { account_ids = [] }
      }
    }
  }

  expect_failures = [var.snapshots]
}

################################################################################
# Test: account-only sharing does not warn
################################################################################

run "account_sharing_no_public_warning" {
  command = plan

  variables {
    project_name    = "demo"
    environment     = "dev"
    enable_image    = true
    enable_snapshot = true
    images = {
      shared = {
        image_name        = "shared"
        vm_id             = "i-12345678"
        launch_permission = { account_ids = ["111111111111"] }
      }
    }
    snapshots = {
      shared = {
        volume_id                = "vol-12345678"
        create_volume_permission = { account_ids = ["111111111111"] }
      }
    }
  }

  assert {
    condition     = length(outscale_image_launch_permission.this) == 1 && length(outscale_snapshot_attributes.this) == 1
    error_message = "Both permissions expected and no public_sharing warning."
  }
}
