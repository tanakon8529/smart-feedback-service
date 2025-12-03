#!/bin/bash
set -euo pipefail
AWS_REGION=${AWS_REGION:-us-east-1}
VPC_CIDR=${VPC_CIDR:-10.0.0.0/16}
AZS_CSV=${AZS:-"${AWS_REGION}a,${AWS_REGION}b"}
PUBLIC_CIDRS_CSV=${PUBLIC_CIDRS:-"10.0.1.0/24,10.0.2.0/24"}
PRIVATE_CIDRS_CSV=${PRIVATE_CIDRS:-"10.0.101.0/24,10.0.102.0/24"}
TAG_PROJECT=${TAG_PROJECT:-smart-feedback}

IFS=',' read -r AZ1 AZ2 <<< "$AZS_CSV"
IFS=',' read -r PUB1_CIDR PUB2_CIDR <<< "$PUBLIC_CIDRS_CSV"
IFS=',' read -r PRIV1_CIDR PRIV2_CIDR <<< "$PRIVATE_CIDRS_CSV"

VPC_ID=$(aws ec2 create-vpc --region "$AWS_REGION" --cidr-block "$VPC_CIDR" --query 'Vpc.VpcId' --output text)
aws ec2 create-tags --region "$AWS_REGION" --resources "$VPC_ID" --tags Key=Name,Value=$TAG_PROJECT-vpc Key=Project,Value=$TAG_PROJECT
aws ec2 modify-vpc-attribute --region "$AWS_REGION" --vpc-id "$VPC_ID" --enable-dns-hostnames
IGW_ID=$(aws ec2 create-internet-gateway --region "$AWS_REGION" --query 'InternetGateway.InternetGatewayId' --output text)
aws ec2 attach-internet-gateway --region "$AWS_REGION" --internet-gateway-id "$IGW_ID" --vpc-id "$VPC_ID"

PUB1_ID=$(aws ec2 create-subnet --region "$AWS_REGION" --vpc-id "$VPC_ID" --cidr-block "$PUB1_CIDR" --availability-zone "$AZ1" --query 'Subnet.SubnetId' --output text)
PUB2_ID=$(aws ec2 create-subnet --region "$AWS_REGION" --vpc-id "$VPC_ID" --cidr-block "$PUB2_CIDR" --availability-zone "$AZ2" --query 'Subnet.SubnetId' --output text)
aws ec2 modify-subnet-attribute --region "$AWS_REGION" --subnet-id "$PUB1_ID" --map-public-ip-on-launch
aws ec2 modify-subnet-attribute --region "$AWS_REGION" --subnet-id "$PUB2_ID" --map-public-ip-on-launch
aws ec2 create-tags --region "$AWS_REGION" --resources "$PUB1_ID" "$PUB2_ID" --tags Key=Name,Value=$TAG_PROJECT-public Key=Project,Value=$TAG_PROJECT

PUB_RT_ID=$(aws ec2 create-route-table --region "$AWS_REGION" --vpc-id "$VPC_ID" --query 'RouteTable.RouteTableId' --output text)
aws ec2 create-route --region "$AWS_REGION" --route-table-id "$PUB_RT_ID" --destination-cidr-block 0.0.0.0/0 --gateway-id "$IGW_ID" >/dev/null
aws ec2 associate-route-table --region "$AWS_REGION" --subnet-id "$PUB1_ID" --route-table-id "$PUB_RT_ID" >/dev/null
aws ec2 associate-route-table --region "$AWS_REGION" --subnet-id "$PUB2_ID" --route-table-id "$PUB_RT_ID" >/dev/null

PRIV1_ID=$(aws ec2 create-subnet --region "$AWS_REGION" --vpc-id "$VPC_ID" --cidr-block "$PRIV1_CIDR" --availability-zone "$AZ1" --query 'Subnet.SubnetId' --output text)
PRIV2_ID=$(aws ec2 create-subnet --region "$AWS_REGION" --vpc-id "$VPC_ID" --cidr-block "$PRIV2_CIDR" --availability-zone "$AZ2" --query 'Subnet.SubnetId' --output text)
aws ec2 create-tags --region "$AWS_REGION" --resources "$PRIV1_ID" "$PRIV2_ID" --tags Key=Name,Value=$TAG_PROJECT-private Key=Project,Value=$TAG_PROJECT

EIP_ALLOC_ID=$(aws ec2 allocate-address --region "$AWS_REGION" --domain vpc --query 'AllocationId' --output text)
NAT_ID=$(aws ec2 create-nat-gateway --region "$AWS_REGION" --subnet-id "$PUB1_ID" --allocation-id "$EIP_ALLOC_ID" --query 'NatGateway.NatGatewayId' --output text)
aws ec2 wait nat-gateway-available --region "$AWS_REGION" --nat-gateway-ids "$NAT_ID"

PRIV_RT_ID=$(aws ec2 create-route-table --region "$AWS_REGION" --vpc-id "$VPC_ID" --query 'RouteTable.RouteTableId' --output text)
aws ec2 create-route --region "$AWS_REGION" --route-table-id "$PRIV_RT_ID" --destination-cidr-block 0.0.0.0/0 --nat-gateway-id "$NAT_ID" >/dev/null
aws ec2 associate-route-table --region "$AWS_REGION" --subnet-id "$PRIV1_ID" --route-table-id "$PRIV_RT_ID" >/dev/null
aws ec2 associate-route-table --region "$AWS_REGION" --subnet-id "$PRIV2_ID" --route-table-id "$PRIV_RT_ID" >/dev/null

echo VPC_ID=$VPC_ID
echo PUBLIC_SUBNET_IDS=$PUB1_ID,$PUB2_ID
echo PRIVATE_SUBNET_IDS=$PRIV1_ID,$PRIV2_ID
echo IGW_ID=$IGW_ID
echo NAT_ID=$NAT_ID
