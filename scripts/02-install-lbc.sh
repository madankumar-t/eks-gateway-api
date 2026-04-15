#!/usr/bin/env bash
set -euo pipefail
source "$(cd -- "$(dirname -- "$0")" && pwd)/common.sh"
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT
curl -fsSL -o "$TMP_DIR/iam_policy.json" https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.14.1/docs/install/iam_policy.json
if ! aws iam get-policy --policy-arn "arn:aws:iam::${AWS_ACCOUNT_ID}:policy/AWSLoadBalancerControllerIAMPolicy" >/dev/null 2>&1; then
  aws iam create-policy --policy-name AWSLoadBalancerControllerIAMPolicy --policy-document "file://$TMP_DIR/iam_policy.json"
else
  echo "IAM policy AWSLoadBalancerControllerIAMPolicy already exists"
fi
eksctl create iamserviceaccount \
  --cluster "$CLUSTER_NAME" \
  --region "$AWS_REGION" \
  --namespace kube-system \
  --name aws-load-balancer-controller \
  --attach-policy-arn "arn:aws:iam::${AWS_ACCOUNT_ID}:policy/AWSLoadBalancerControllerIAMPolicy" \
  --override-existing-serviceaccounts \
  --approve
helm repo add eks https://aws.github.io/eks-charts >/dev/null 2>&1 || true
helm repo update
VPC_ID=$(aws eks describe-cluster --name "$CLUSTER_NAME" --region "$AWS_REGION" --query 'cluster.resourcesVpcConfig.vpcId' --output text)
if ! helm status aws-load-balancer-controller -n kube-system >/dev/null 2>&1; then
  helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
    -n kube-system \
    --set clusterName="$CLUSTER_NAME" \
    --set serviceAccount.create=false \
    --set serviceAccount.name=aws-load-balancer-controller \
    --set region="$AWS_REGION" \
    --set vpcId="$VPC_ID"
else
  echo "aws-load-balancer-controller already installed"
fi
kubectl rollout status deployment/aws-load-balancer-controller -n kube-system
