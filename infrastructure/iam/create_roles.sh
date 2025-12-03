#!/bin/bash
set -euo pipefail
CLUSTER_ROLE_NAME=${CLUSTER_ROLE_NAME:-SmartFeedbackEKSClusterRole}
NODE_ROLE_NAME=${NODE_ROLE_NAME:-SmartFeedbackNodeRole}

CLUSTER_TRUST=$(cat <<'JSON'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {"Service": "eks.amazonaws.com"},
      "Action": "sts:AssumeRole"
    }
  ]
}
JSON
)

NODE_TRUST=$(cat <<'JSON'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {"Service": "ec2.amazonaws.com"},
      "Action": "sts:AssumeRole"
    }
  ]
}
JSON
)

CLUSTER_ROLE_ARN=$(aws iam create-role --role-name "$CLUSTER_ROLE_NAME" --assume-role-policy-document "$CLUSTER_TRUST" --query 'Role.Arn' --output text || aws iam get-role --role-name "$CLUSTER_ROLE_NAME" --query 'Role.Arn' --output text)
aws iam attach-role-policy --role-name "$CLUSTER_ROLE_NAME" --policy-arn arn:aws:iam::aws:policy/AmazonEKSClusterPolicy >/dev/null || true
aws iam attach-role-policy --role-name "$CLUSTER_ROLE_NAME" --policy-arn arn:aws:iam::aws:policy/AmazonEKSServicePolicy >/dev/null || true

NODE_ROLE_ARN=$(aws iam create-role --role-name "$NODE_ROLE_NAME" --assume-role-policy-document "$NODE_TRUST" --query 'Role.Arn' --output text || aws iam get-role --role-name "$NODE_ROLE_NAME" --query 'Role.Arn' --output text)
aws iam attach-role-policy --role-name "$NODE_ROLE_NAME" --policy-arn arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy >/dev/null || true
aws iam attach-role-policy --role-name "$NODE_ROLE_NAME" --policy-arn arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy >/dev/null || true
aws iam attach-role-policy --role-name "$NODE_ROLE_NAME" --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly >/dev/null || true

echo CLUSTER_ROLE_ARN=$CLUSTER_ROLE_ARN
echo NODE_ROLE_ARN=$NODE_ROLE_ARN
