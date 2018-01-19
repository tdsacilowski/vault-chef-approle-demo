output "chef-node-connection" {
  value = "${format("ssh -i %s.pem %s@%s", var.key_name, "ubuntu", module.chef_node.chef-node-public-ip)}"
}

output "approle-role-id" {
  value = "${module.chef_node.approle-role-id}"
}
