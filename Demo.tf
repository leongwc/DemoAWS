resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "main"
  }
}

resource "aws_security_group" "allow_tls" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "Allow TCP 443"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["<cidr>"]
  }

  ingress {
    description = "Allow TCP 4433 "
    from_port   = 4433
    to_port     = 4433
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_tls"
  }
}

resource "aws_flow_log" "main" {
  vpc_id          = "${aws_vpc.main.id}"
  iam_role_arn    = "<iam_role_arn>"
  log_destination = "${aws_s3_bucket.main.arn}"
  traffic_type    = "ALL"

  tags = {
    GeneratedBy      = "Accurics"
    ParentResourceId = "aws_vpc.main"
  }
}
resource "aws_s3_bucket" "main" {
  bucket        = "main_flow_log_s3_bucket"
  acl           = "private"
  force_destroy = true

  versioning {
    enabled    = true
    mfa_delete = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}
resource "aws_s3_bucket_policy" "main" {
  bucket = "${aws_s3_bucket.main.id}"

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "main-restrict-access-to-users-or-roles",
      "Effect": "Allow",
      "Principal": [
        {
          "AWS": [
            <principal_arn>
          ]
        }
      ],
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::${aws_s3_bucket.main.id}/*"
    }
  ]
}
POLICY
}