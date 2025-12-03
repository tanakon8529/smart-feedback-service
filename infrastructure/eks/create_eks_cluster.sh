#!/bin/bash
set -euo pipefail
AWS_REGION=${AWS_REGION:-us-east-1}
CLUSTER_NAME=${CLUSTER_NAME:-smart-feedback-eks}
PUBLIC_SUBNET_IDS=${PUBLIC_SUBNET_IDS:-}
PRIVATE_SUBNET_IDS=${PRIVATE_SUBNET_IDS:-}
NODES=${NODES:-2}
NODE_TYPE=${NODE_TYPE:-t3.medium}

PATH="$HOME/bin:$PATH"
mkdir -p "$HOME/bin"
if ! command -v eksctl >/dev/null 2>&1; then
  curl -sL https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_Linux_amd64.tar.gz | tar xz -C /tmp
  mv /tmp/eksctl "$HOME/bin/eksctl"
fi

TAGS=${TAGS:-Project=smart-feedback}
CMD=(eksctl create cluster --name "$CLUSTER_NAME" --region "$AWS_REGION" --with-oidc --managed --nodegroup-name ng-1 --nodes "$NODES" --node-type "$NODE_TYPE" --tags "$TAGS")
if [ -n "$PUBLIC_SUBNET_IDS" ]; then CMD+=(--vpc-public-subnets "$PUBLIC_SUBNET_IDS"); fi
if [ -n "$PRIVATE_SUBNET_IDS" ]; then CMD+=(--vpc-private-subnets "$PRIVATE_SUBNET_IDS"); fi
"${CMD[@]}"

aws eks update-kubeconfig --region "$AWS_REGION" --name "$CLUSTER_NAME"
aws eks update-cluster-config --region "$AWS_REGION" --name "$CLUSTER_NAME" --logging '{"clusterLogging":[{"types":["api","audit","authenticator","controllerManager","scheduler"],"enabled":true}]}'

echo CLUSTER_NAME=$CLUSTER_NAME
