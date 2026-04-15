# Detailed step-by-step guide

## 1. Get the repo

Download the archive from ChatGPT or push these files to your own GitHub repo.

## 2. Fill in environment variables

```bash
cp policies/variables.env.example .env
vi .env
```

Required values:

- `AWS_REGION=us-east-2`
- `CLUSTER_NAME=eks-oidc-test`
- `NAMESPACE=ingress-nginx`
- `APP_NAME=mygateway-app`
- `AWS_ACCOUNT_ID`
- `ACM_CERT_ARN`
- `HOSTED_ZONE_ID`
- `APP_FQDN`
- `PUBLIC_SUBNET_IDS` space-separated
- `PRIVATE_SUBNET_IDS` space-separated

## 3. Run the scripts in order

```bash
bash scripts/01-prereqs.sh
bash scripts/02-install-lbc.sh
bash scripts/03-install-gateway-crds.sh
bash scripts/04-deploy-app-and-gateway.sh
bash scripts/05-install-externaldns.sh
bash scripts/06-verify.sh
```

## What each script does

### `01-prereqs.sh`

- loads `.env`
- verifies required tools exist
- updates kubeconfig
- associates OIDC provider
- tags public subnets for internet-facing ALB
- tags private subnets for internal separation

### `02-install-lbc.sh`

- downloads AWS Load Balancer Controller IAM policy
- creates or reuses the IAM policy
- creates IRSA service account in `kube-system`
- installs the controller with Helm

### `03-install-gateway-crds.sh`

- installs Gateway API CRDs
- installs AWS LBC Gateway CRDs
- verifies the CRDs exist

### `04-deploy-app-and-gateway.sh`

- creates the app namespace
- deploys the sample app and Service
- creates `GatewayClass`
- creates `LoadBalancerConfiguration` with ACM HTTPS listener
- creates `TargetGroupConfiguration` with tuned health checks
- creates HTTPS-only `Gateway`
- creates `HTTPRoute`

### `05-install-externaldns.sh`

- renders the Route 53 policy from template
- creates or reuses the IAM policy
- creates IRSA service account
- installs ExternalDNS with Gateway API sources

### `06-verify.sh`

- checks controller and ExternalDNS
- prints Gateway and Route status
- shows logs
- checks Route 53 record
- attempts HTTPS test

## Troubleshooting

### Gateway has no address

```bash
kubectl describe gateway -n ingress-nginx mygateway-app-gateway
kubectl logs -n kube-system deploy/aws-load-balancer-controller
```

### DNS record missing

```bash
kubectl logs -n kube-system deploy/external-dns
aws route53 list-resource-record-sets --hosted-zone-id <zone-id>
```

### Health checks failing

Check the backend app responds on `/` with 200-399.
