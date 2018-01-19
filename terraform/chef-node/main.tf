provider "aws" {
  region = "${var.aws_region}"
}

provider "vault" {
  address = "${var.vault_address}"
}

//--------------------------------------------------------------------
// Modules

module "chef_node" {
  source = "../modules/instance-chef-node"

  aws_region          = "${var.aws_region}"
  environment_name    = "${var.environment_name}"
  vpc_id              = "${var.vpc_id}"
  instance_type       = "${var.instance_type}"
  subnet_id           = "${var.subnet_id}"
  key_name            = "${var.key_name}"
  chef_server_address = "${var.chef_server_address}"
  ec2_pem             = "${var.ec2_pem}"
  chef_pem            = "${var.chef_pem}"
}
