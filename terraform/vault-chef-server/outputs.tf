output "vault-connection" {
  value = "${format("ssh -i %s.pem %s@%s", var.key_name, "ubuntu", module.vault_instance.vault-public-ip)}"
}
