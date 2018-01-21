#!/usr/bin/env bash
set -e

shopt -s nullglob

function provision() {
    set +e
    pushd "$1" > /dev/null
    for f in $(ls "$1"/*.json); do
      p="$1/${f%.json}"

      if [[ $1 =~ ^sys/policy.* ]]
      then
          string="$(echo "$(cat ${f})" | jq '@json')"
          payload='{"rules":'"${string}"'}'
      else
          payload="$(cat ${f})"
      fi

      curl \
        --location \
        --header "X-Vault-Token: ${VAULT_TOKEN}" \
        --data "$(echo "${payload}")" \
        --silent \
        "${VAULT_ADDR}/v1/${p}" \
        | jq .
    done
    popd > /dev/null
    set -e
}

curl \
    --request PUT \
    --data @data/sys/init/init.json \
    $VAULT_ADDR/v1/sys/init > init-response.json

export VAULT_TOKEN=$(cat init-response.json | jq -r .root_token)

#echo "Verifying Vault is unsealed"
#vault status > /dev/null

pushd data >/dev/null
provision sys/auth
#provision sys/mounts
provision sys/policy
#provision postgresql/config
#provision postgresql/roles
provision auth/approle/roles
popd > /dev/null