#!/usr/bin/env bash
set -x
exec > >(tee /var/log/tf-user-data.log|logger -t user-data ) 2>&1

# Install jq
sudo curl --silent -Lo /bin/jq https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64
sudo chmod +x /bin/jq

# Write AppRole RoleID
echo "export APPROLE_ROLEID=$(echo '${tpl_role_id}' | jq -r .role_id)" >> /etc/environment

# Write Vault address
echo "export VAULT_ADDR=${tpl_vault_addr}" >> /etc/environment
