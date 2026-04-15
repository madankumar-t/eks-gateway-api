#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
if [[ ! -f "$ROOT_DIR/.env" ]]; then
  echo "Missing $ROOT_DIR/.env. Copy policies/variables.env.example to .env and edit it."
  exit 1
fi
set -a
source "$ROOT_DIR/.env"
set +a
required_vars=(AWS_REGION CLUSTER_NAME NAMESPACE APP_NAME AWS_ACCOUNT_ID ACM_CERT_ARN HOSTED_ZONE_ID APP_FQDN PUBLIC_SUBNET_IDS PRIVATE_SUBNET_IDS)
for v in "${required_vars[@]}"; do
  if [[ -z "${!v:-}" ]]; then
    echo "Missing required variable: $v"
    exit 1
  fi
done
