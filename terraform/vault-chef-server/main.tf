provider "aws" {
  region = "${var.aws_region}"
}

//--------------------------------------------------------------------
// Modules

module "vault_instance" {
  source = "../modules/vault-instance"

  aws_region       = "${var.aws_region}"
  environment_name = "${var.environment_name}"
  s3_bucket_name   = "${var.s3_bucket_name}"
  vault_zip_file   = "${var.vault_zip_file}"
  vpc_id           = "${var.vpc_id}"
  instance_type    = "${var.instance_type}"
  subnet_id        = "${var.subnet_id}"
  key_name         = "${var.key_name}"
}
