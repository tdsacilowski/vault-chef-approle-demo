output "vault-connection" {
  value = "${format("ssh -i %s %s@%s", var.key_name, "ubuntu", module.vault_instance.vault-public-ip)}"
}
