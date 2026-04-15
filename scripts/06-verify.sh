#!/usr/bin/env bash
set -euo pipefail
source "$(cd -- "$(dirname -- "$0")" && pwd)/common.sh"
kubectl get pods -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller
kubectl get deployment -n kube-system external-dns || true
kubectl get gatewayclass
kubectl get gateway -n "$NAMESPACE"
kubectl get httproute -n "$NAMESPACE"
kubectl get targetgroupconfiguration -n "$NAMESPACE"
kubectl describe gateway "${APP_NAME}-gateway" -n "$NAMESPACE" || true
kubectl logs -n kube-system deploy/aws-load-balancer-controller --tail=50 || true
kubectl logs -n kube-system deploy/external-dns --tail=50 || true
aws route53 list-resource-record-sets --hosted-zone-id "$HOSTED_ZONE_ID" --query "ResourceRecordSets[?Name == '${APP_FQDN}.']" || true
if kubectl get gateway "${APP_NAME}-gateway" -n "$NAMESPACE" -o jsonpath='{.status.addresses[0].value}' >/dev/null 2>&1; then
  ALB_DNS=$(kubectl get gateway "${APP_NAME}-gateway" -n "$NAMESPACE" -o jsonpath='{.status.addresses[0].value}')
  echo "ALB_DNS=$ALB_DNS"
  curl -Ik "https://${APP_FQDN}" || true
fi
