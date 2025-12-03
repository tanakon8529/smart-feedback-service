#!/bin/bash
set -euo pipefail
AWS_REGION=${AWS_REGION:-us-east-1}
export AWS_REGION

OUT_VPC=$(./infrastructure/vpc/create_vpc.sh)
eval "$OUT_VPC"

OUT_IAM=$(./infrastructure/iam/create_roles.sh)
eval "$OUT_IAM"

./infrastructure/eks/create_eks_cluster.sh \
  ${PUBLIC_SUBNET_IDS:+PUBLIC_SUBNET_IDS=$PUBLIC_SUBNET_IDS} \
  ${PRIVATE_SUBNET_IDS:+PRIVATE_SUBNET_IDS=$PRIVATE_SUBNET_IDS} \
  ${AWS_REGION:+AWS_REGION=$AWS_REGION}

echo VPC_ID=$VPC_ID
echo PUBLIC_SUBNET_IDS=$PUBLIC_SUBNET_IDS
echo PRIVATE_SUBNET_IDS=$PRIVATE_SUBNET_IDS
echo CLUSTER_NAME=${CLUSTER_NAME:-smart-feedback-eks}
