# EKS Gateway API on AWS (HTTPS-only, ACM, ExternalDNS, health checks)

This repo deploys a sample app behind Kubernetes Gateway API on Amazon EKS using:

- AWS Load Balancer Controller
- Gateway API CRDs
- ALB-backed Gateway with HTTPS only
- ACM certificate termination
- Public vs private subnet separation
- ExternalDNS with Route 53
- Tuned target group health checks

## Prerequisites

- Existing EKS cluster
- `kubectl`, `aws`, `helm`, `eksctl`, `curl`, `jq`
- IAM permissions to create policies and roles
- Route 53 hosted zone
- ACM certificate in the same region as the EKS cluster

## Quick start

```bash
cp policies/variables.env.example .env
# edit .env with your values

bash scripts/01-prereqs.sh
bash scripts/02-install-lbc.sh
bash scripts/03-install-gateway-crds.sh
bash scripts/04-deploy-app-and-gateway.sh
bash scripts/05-install-externaldns.sh
bash scripts/06-verify.sh
```

Detailed instructions: `docs/step-by-step.md`
