#!/bin/bash

# Ocean Hazard FastAPI Backend Deployment Script
# This script deploys the Ocean Hazard backend to AWS

set -e

# Configuration
AWS_REGION="us-east-1"
STACK_NAME="ocean-hazard-backend"
ECR_REPOSITORY="ocean-hazard-api"
IMAGE_TAG="latest"

echo "🚀 Starting Ocean Hazard Backend Deployment..."

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo "❌ AWS CLI is not installed. Please install it first."
    exit 1
fi

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Please install it first."
    exit 1
fi

# Check AWS credentials
echo "🔐 Checking AWS credentials..."
aws sts get-caller-identity > /dev/null || {
    echo "❌ AWS credentials not configured. Please run 'aws configure' first."
    exit 1
}

# Get AWS account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo "📋 AWS Account ID: $AWS_ACCOUNT_ID"

# Create ECR repository if it doesn't exist
echo "📦 Creating ECR repository..."
aws ecr describe-repositories --repository-names $ECR_REPOSITORY --region $AWS_REGION > /dev/null 2>&1 || {
    echo "Creating ECR repository: $ECR_REPOSITORY"
    aws ecr create-repository --repository-name $ECR_REPOSITORY --region $AWS_REGION
}

# Login to ECR
echo "🔑 Logging in to ECR..."
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com

# Build Docker image
echo "🏗️ Building Docker image..."
docker build -t $ECR_REPOSITORY:$IMAGE_TAG .

# Tag image for ECR
docker tag $ECR_REPOSITORY:$IMAGE_TAG $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPOSITORY:$IMAGE_TAG

# Push image to ECR
echo "📤 Pushing image to ECR..."
docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPOSITORY:$IMAGE_TAG

# Deploy CloudFormation stack
echo "☁️ Deploying CloudFormation stack..."
aws cloudformation deploy \
    --template-file aws-deployment.yml \
    --stack-name $STACK_NAME \
    --parameter-overrides \
        Environment=production \
        DatabaseInstanceClass=db.t3.micro \
        ApplicationInstanceType=t3.micro \
    --capabilities CAPABILITY_IAM \
    --region $AWS_REGION

# Get stack outputs
echo "📊 Getting deployment outputs..."
aws cloudformation describe-stacks \
    --stack-name $STACK_NAME \
    --region $AWS_REGION \
    --query 'Stacks[0].Outputs'

echo "✅ Deployment completed successfully!"
echo "🌊 Ocean Hazard Backend is now running on AWS"
echo "📋 Check the CloudFormation console for detailed information"


