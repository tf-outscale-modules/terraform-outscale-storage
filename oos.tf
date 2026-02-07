# OOS (Outscale Object Storage) — S3-compatible
#
# The AWS provider must be configured with Outscale OOS endpoints in the root module:
#
#   provider "aws" {
#     region     = "eu-west-2"
#     access_key = var.access_key_id
#     secret_key = var.secret_key_id
#
#     skip_credentials_validation = true
#     skip_requesting_account_id  = true
#     skip_region_validation      = true
#
#     endpoints {
#       s3 = "https://oos.eu-west-2.outscale.com"
#     }
#   }

################################################################################
# OOS Buckets
################################################################################

resource "aws_s3_bucket" "this" {
  for_each = var.enable_oos ? var.oos_buckets : {}

  bucket        = each.value.bucket
  force_destroy = each.value.force_destroy

  tags = merge(local.common_tags, each.value.tags)
}

################################################################################
# OOS Objects
################################################################################

resource "aws_s3_object" "this" {
  for_each = var.enable_oos ? var.oos_objects : {}

  bucket = (
    each.value.bucket_key != null
    ? aws_s3_bucket.this[each.value.bucket_key].id
    : each.value.bucket
  )

  key     = each.value.key
  source  = each.value.source
  content = each.value.content

  tags = merge(local.common_tags, each.value.tags)
}
