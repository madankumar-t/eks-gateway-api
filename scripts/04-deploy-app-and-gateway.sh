#!/usr/bin/env bash
set -euo pipefail
source "$(cd -- "$(dirname -- "$0")" && pwd)/common.sh"
if ! command -v envsubst >/dev/null 2>&1; then
  echo "Missing command: envsubst (install gettext)"
  exit 1
fi
kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -
for f in app.yaml gatewayclass.yaml loadbalancerconfiguration.yaml targetgroupconfiguration.yaml gateway.yaml httproute.yaml; do
  envsubst < "$ROOT_DIR/k8s/$f" | kubectl apply -f -
done
kubectl get all -n "$NAMESPACE"
kubectl get gateway,httproute,targetgroupconfiguration -n "$NAMESPACE"
