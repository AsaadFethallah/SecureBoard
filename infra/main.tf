terraform {
  required_version = ">= 1.10.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "eu-west-1"
}


# -------------------------------------------------------------------
# SecureBoard artifact bucket
# -------------------------------------------------------------------

resource "aws_s3_bucket" "artifacts" {
  # checkov:skip=CKV_AWS_144:Cross-region replication is not required for this single-region lab environment.
  # checkov:skip=CKV2_AWS_62:No application currently consumes S3 event notifications.

  bucket = "secureboard-artifacts-demo"
}


resource "aws_s3_bucket_public_access_block" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}


resource "aws_s3_bucket_server_side_encryption_configuration" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }

    bucket_key_enabled = true
  }
}


resource "aws_s3_bucket_versioning" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id

  versioning_configuration {
    status = "Enabled"
  }
}


resource "aws_s3_bucket_lifecycle_configuration" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id

  depends_on = [
    aws_s3_bucket_versioning.artifacts
  ]

  rule {
    id     = "artifact-retention"
    status = "Enabled"

    filter {}

    expiration {
      days = 90
    }

    noncurrent_version_expiration {
      noncurrent_days = 30
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}


# -------------------------------------------------------------------
# Dedicated access-log bucket
# -------------------------------------------------------------------

resource "aws_s3_bucket" "logs" {
  # checkov:skip=CKV_AWS_18:Dedicated log destination bucket; recursive access logging is intentionally disabled.
  # checkov:skip=CKV_AWS_144:Cross-region replication is not required for this single-region lab environment.
  # checkov:skip=CKV2_AWS_62:No event-driven consumer exists for the access-log bucket.

  bucket = "secureboard-access-logs-demo"
}


resource "aws_s3_bucket_public_access_block" "logs" {
  bucket = aws_s3_bucket.logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}


resource "aws_s3_bucket_server_side_encryption_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }

    bucket_key_enabled = true
  }
}


resource "aws_s3_bucket_versioning" "logs" {
  bucket = aws_s3_bucket.logs.id

  versioning_configuration {
    status = "Enabled"
  }
}


resource "aws_s3_bucket_lifecycle_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id

  depends_on = [
    aws_s3_bucket_versioning.logs
  ]

  rule {
    id     = "log-retention"
    status = "Enabled"

    filter {}

    expiration {
      days = 180
    }

    noncurrent_version_expiration {
      noncurrent_days = 30
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}


resource "aws_s3_bucket_logging" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id

  target_bucket = aws_s3_bucket.logs.id
  target_prefix = "artifact-access/"
}