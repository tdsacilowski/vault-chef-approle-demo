//--------------------------------------------------------------------
// Resources

resource "aws_kms_key" "vault" {
  description             = "Vault unseal key"
  deletion_window_in_days = 7

  tags {
    Name = "${var.environment_name}-vault-kms-unseal-key"
  }
}

resource "aws_kms_alias" "vault" {
  name          = "alias/${var.environment_name}-vault-kms-unseal-key"
  target_key_id = "${aws_kms_key.vault.key_id}"
}

resource "aws_instance" "vault" {
  ami                         = "${data.aws_ami.ubuntu.id}"
  instance_type               = "${var.instance_type}"
  subnet_id                   = "${var.subnet_id}"
  key_name                    = "${var.key_name}"
  vpc_security_group_ids      = ["${aws_security_group.vault.id}"]
  associate_public_ip_address = true
  iam_instance_profile        = "${aws_iam_instance_profile.vault.id}"

  tags {
    Name = "${var.environment_name}"
  }

  user_data = "${data.template_file.vault.rendered}"
}

resource "aws_security_group" "vault" {
  name        = "${var.environment_name}-vault-sg"
  description = "Access to Vault server"
  vpc_id      = "${var.vpc_id}"

  tags {
    Name = "${var.environment_name}"
  }

  # SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Vault Client Traffic
  ingress {
    from_port   = 8200
    to_port     = 8200
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Chef Server (HTTP)
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Chef Server (HTTPS)
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_iam_role" "vault" {
  name               = "${var.environment_name}-vault-role"
  assume_role_policy = "${data.aws_iam_policy_document.assume_role.json}"
}

resource "aws_iam_role_policy" "vault" {
  name   = "${var.environment_name}-vault-role-policy"
  role   = "${aws_iam_role.vault.id}"
  policy = "${data.aws_iam_policy_document.vault.json}"
}

resource "aws_iam_instance_profile" "vault" {
  name = "${var.environment_name}-vault-instance-profile"
  role = "${aws_iam_role.vault.name}"
}

//--------------------------------------------------------------------
// Data Sources

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-xenial-16.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "vault" {
  statement {
    sid    = "VaultKMSUnseal"
    effect = "Allow"

    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:DescribeKey",
    ]

    resources = ["*"]
  }

  statement {
    sid     = "S3GetObject"
    effect  = "Allow"
    actions = ["s3:GetObject"]

    resources = [
      "arn:aws:s3:::${var.s3_bucket_name}",
      "arn:aws:s3:::${var.s3_bucket_name}/*",
    ]
  }
}

data "template_file" "vault" {
  template = "${file("${path.module}/userdata.tpl")}"

  vars = {
    tpl_aws_region     = "${var.aws_region}"
    tpl_kms_key        = "${aws_kms_key.vault.id}"
    tpl_s3_bucket_name = "${var.s3_bucket_name}"
    tpl_vault_zip_file = "${var.vault_zip_file}"
  }
}
