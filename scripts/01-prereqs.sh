#!/usr/bin/env bash
set -euo pipefail
source "$(cd -- "$(dirname -- "$0")" && pwd)/common.sh"
for cmd in aws kubectl helm eksctl curl jq; do
  command -v "$cmd" >/dev/null || { echo "Missing command: $cmd"; exit 1; }
done
aws eks update-kubeconfig --region "$AWS_REGION" --name "$CLUSTER_NAME"
eksctl utils associate-iam-oidc-provider --cluster "$CLUSTER_NAME" --region "$AWS_REGION" --approve
VPC_ID=$(aws eks describe-cluster --name "$CLUSTER_NAME" --region "$AWS_REGION" --query 'cluster.resourcesVpcConfig.vpcId' --output text)
echo "Cluster VPC: $VPC_ID"
for s in $PUBLIC_SUBNET_IDS; do
  aws ec2 create-tags --region "$AWS_REGION" --resources "$s" --tags Key=kubernetes.io/role/elb,Value=1
  echo "Tagged public subnet: $s"
done
for s in $PRIVATE_SUBNET_IDS; do
  aws ec2 create-tags --region "$AWS_REGION" --resources "$s" --tags Key=kubernetes.io/role/internal-elb,Value=1
  echo "Tagged private subnet: $s"
done
kubectl get nodes
