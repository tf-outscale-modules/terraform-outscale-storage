################################################################################
# Provider configuration for tests
################################################################################

provider "outscale" {
  access_key_id = "test-access-key"
  secret_key_id = "test-secret-key"
  region        = "eu-west-2"
}

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
