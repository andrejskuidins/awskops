provider "aws" {
  region = "eu-north-1"
}

provider "aws" {
  region = "us-east-1"
  alias = "useast1"
}

data "aws_ami" "latest_ubuntu" {
  owners      = ["099720109477"]
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
}

data "aws_availability_zones" "available" {}

resource "aws_iam_user" "user1" {
  name = "kops"
}

resource "aws_iam_user_policy" "kops_policy" {
  name = "kops_policy"
  user = aws_iam_user.user1.id
policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "ec2:*",
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": "s3:*",
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": "route53:*",
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": "iam:*",
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": "sqs:*",
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": "events:*",
            "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_iam_access_key" "kops" {
  user = aws_iam_user.user1.id
}

resource "aws_s3_bucket" "kops_config" {
  provider = aws.useast1

  bucket = "my-kops-test-bucket"
  force_destroy = true
  acl    = "private"

  versioning {
    enabled = true
  }

  tags = {
    Name        = "My kops bucket"
    Environment = "Prod"
  }
}

resource "aws_efs_file_system" "wordpress" {
  creation_token = "my-wordpress"

  tags = {
    Name = "MyWordpress"
  }
}


resource "aws_efs_mount_target" "wordpress_mount" {
  file_system_id = aws_efs_file_system.wordpress.id
  subnet_id      = "subnet-0c41cd7d0168325db"
  security_groups = ["sg-090822a9726a1f70c"]
}

output "created_iam_users_all" {
  value = aws_iam_user.user1.id
}

output "access_key" {
  value = aws_iam_access_key.kops.id
}

output "secret_key" {
  sensitive = true
  value = aws_iam_access_key.kops.secret
}

output "aws_availability_zones" {
  value = data.aws_availability_zones.available.names
}

output "wordpress_volume_id" {
  value = aws_efs_file_system.wordpress.id
}

output "wordpress_volume_dns" {
  value = aws_efs_file_system.wordpress.dns_name
}
