# The mailbox Ansible uses to pass module files to the server via SSM.
# bucket_prefix lets AWS add a random unique ending (names are global).
resource "aws_s3_bucket" "ansible_transfer" {
  bucket_prefix = "freshtrack-ansible-"
  force_destroy = true # destroy works even if a crashed run left files behind

  tags = {
    Name    = "${var.project_name}-${var.environment}-ansible-transfer"
    Purpose = "ansible-ssm-transfer"
  }
}

# Lock: encrypt everything at rest
resource "aws_s3_bucket_server_side_encryption_configuration" "ansible_transfer" {
  bucket = aws_s3_bucket.ansible_transfer.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# No windows: block all public access
resource "aws_s3_bucket_public_access_block" "ansible_transfer" {
  bucket                  = aws_s3_bucket.ansible_transfer.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Cleaner: anything left behind is deleted after 1 day
resource "aws_s3_bucket_lifecycle_configuration" "ansible_transfer" {
  bucket = aws_s3_bucket.ansible_transfer.id
  rule {
    id     = "expire-leftovers"
    status = "Enabled"
    filter {}
    expiration {
      days = 1
    }
  }
}

# Armoured vans only: refuse any request that isn't HTTPS
data "aws_iam_policy_document" "ansible_transfer_tls_only" {
  statement {
    sid       = "DenyInsecureTransport"
    effect    = "Deny"
    actions   = ["s3:*"]
    resources = [aws_s3_bucket.ansible_transfer.arn, "${aws_s3_bucket.ansible_transfer.arn}/*"]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_s3_bucket_policy" "ansible_transfer" {
  bucket = aws_s3_bucket.ansible_transfer.id
  policy = data.aws_iam_policy_document.ansible_transfer_tls_only.json
}

