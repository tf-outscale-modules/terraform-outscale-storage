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
