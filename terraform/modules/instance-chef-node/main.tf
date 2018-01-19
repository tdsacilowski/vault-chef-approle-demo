//--------------------------------------------------------------------
// Resources

resource "aws_instance" "chef-node" {
  ami                         = "${data.aws_ami.ubuntu.id}"
  instance_type               = "${var.instance_type}"
  subnet_id                   = "${var.subnet_id}"
  key_name                    = "${var.key_name}"
  vpc_security_group_ids      = ["${aws_security_group.chef-node.id}"]
  associate_public_ip_address = true

  tags {
    Name = "${var.environment_name}-chef-node"
  }

  user_data = "${data.template_file.role-id.rendered}"

  provisioner "chef" {
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = "${var.ec2_pem}"
    }

    node_name               = "chef-node-test"
    server_url              = "${var.chef_server_address}"
    user_name               = "demo-admin"
    user_key                = "${var.chef_pem}"
    run_list                = ["recipe[learn_chef_apache2]"]
    recreate_client         = true
    fetch_chef_certificates = true
    ssl_verify_mode         = ":verify_none"
  }
}

resource "aws_security_group" "chef-node" {
  name        = "${var.environment_name}-chef-node-sg"
  description = "Access to Chef node"
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

//--------------------------------------------------------------------
// Data Sources

data "vault_generic_secret" "approle" {
  path = "auth/approle/role/app-1/role-id"
}

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

data "template_file" "role-id" {
  template = "${file("${path.module}/userdata.tpl")}"

  vars = {
    tpl_role_id = "${data.vault_generic_secret.approle.data_json}"
  }
}
