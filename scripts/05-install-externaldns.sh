#!/usr/bin/env bash
set -euo pipefail
source "$(cd -- "$(dirname -- "$0")" && pwd)/common.sh"
if ! command -v envsubst >/dev/null 2>&1; then
  echo "Missing command: envsubst (install gettext)"
  exit 1
fi
TMP_POLICY=$(mktemp)
trap 'rm -f "$TMP_POLICY"' EXIT
envsubst < "$ROOT_DIR/policies/externaldns-policy.tpl.json" > "$TMP_POLICY"
if ! aws iam get-policy --policy-arn "arn:aws:iam::${AWS_ACCOUNT_ID}:policy/AllowExternalDNSUpdates-${CLUSTER_NAME}" >/dev/null 2>&1; then
  aws iam create-policy --policy-name "AllowExternalDNSUpdates-${CLUSTER_NAME}" --policy-document "file://$TMP_POLICY"
else
  echo "IAM policy AllowExternalDNSUpdates-${CLUSTER_NAME} already exists"
fi
eksctl create iamserviceaccount \
  --cluster "$CLUSTER_NAME" \
  --region "$AWS_REGION" \
  --namespace kube-system \
  --name external-dns \
  --attach-policy-arn "arn:aws:iam::${AWS_ACCOUNT_ID}:policy/AllowExternalDNSUpdates-${CLUSTER_NAME}" \
  --override-existing-serviceaccounts \
  --approve
helm repo add external-dns https://kubernetes-sigs.github.io/external-dns/ >/dev/null 2>&1 || true
helm repo update
BASE_DOMAIN=$(echo "$APP_FQDN" | cut -d. -f2-)
if ! helm status external-dns -n kube-system >/dev/null 2>&1; then
  helm install external-dns external-dns/external-dns \
    -n kube-system \
    --set serviceAccount.create=false \
    --set serviceAccount.name=external-dns \
    --set provider=aws \
    --set aws.region="$AWS_REGION" \
    --set txtOwnerId="$CLUSTER_NAME" \
    --set txtPrefix=extdns- \
    --set domainFilters[0]="$BASE_DOMAIN" \
    --set policy=upsert-only \
    --set registry=txt \
    --set sources[0]=gateway-httproute \
    --set sources[1]=gateway-gateway
else
  echo "external-dns already installed"
fi
kubectl rollout status deployment/external-dns -n kube-system
