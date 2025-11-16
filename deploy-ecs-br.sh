#!/bin/bash

# Script de Deploy ECS com Versionamento por Commit Hash
# Uso: ./deploy-ecs-br.sh <cluster-name> <service-name>

set -e

# Verificar parâmetros
if [ $# -ne 2 ]; then
    echo "Uso: $0 <cluster-name> <service-name>"
    echo "Exemplo: $0 cluster-bia service-bia"
    exit 1
fi

CLUSTER_NAME=$1
SERVICE_NAME=$2

# Obter commit hash (7 dígitos)
COMMIT_HASH=$(git rev-parse --short=7 HEAD)
echo "Commit Hash: $COMMIT_HASH"

# Configurações ECR
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
AWS_REGION=$(aws configure get region)
ECR_REPOSITORY="bia"
IMAGE_TAG=$COMMIT_HASH
IMAGE_URI="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPOSITORY:$IMAGE_TAG"

echo "Iniciando deploy para:"
echo "  Cluster: $CLUSTER_NAME"
echo "  Service: $SERVICE_NAME"
echo "  Image: $IMAGE_URI"

# 1. Build da imagem Docker
echo "Building Docker image..."
docker build -t $ECR_REPOSITORY:$IMAGE_TAG .

# 2. Login no ECR
echo "Logging into ECR..."
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com

# 3. Tag da imagem
echo "Tagging image..."
docker tag $ECR_REPOSITORY:$IMAGE_TAG $IMAGE_URI

# 4. Push para ECR
echo "Pushing to ECR..."
docker push $IMAGE_URI

# 5. Obter task definition atual
echo "Getting current task definition..."
TASK_DEFINITION=$(aws ecs describe-services --cluster $CLUSTER_NAME --services $SERVICE_NAME --query 'services[0].taskDefinition' --output text)
TASK_FAMILY=$(echo $TASK_DEFINITION | cut -d'/' -f2 | cut -d':' -f1)

# 6. Criar nova task definition
echo "Creating new task definition..."
aws ecs describe-task-definition --task-definition $TASK_DEFINITION --query 'taskDefinition' > task-def-temp.json

# Atualizar imagem na task definition
jq --arg IMAGE_URI "$IMAGE_URI" '.containerDefinitions[0].image = $IMAGE_URI | del(.taskDefinitionArn, .revision, .status, .requiresAttributes, .placementConstraints, .compatibilities, .registeredAt, .registeredBy)' task-def-temp.json > task-def-new.json

# Registrar nova task definition
NEW_TASK_DEF=$(aws ecs register-task-definition --cli-input-json file://task-def-new.json --query 'taskDefinition.taskDefinitionArn' --output text)

echo "New task definition: $NEW_TASK_DEF"

# 7. Atualizar serviço
echo "Updating ECS service..."
aws ecs update-service --cluster $CLUSTER_NAME --service $SERVICE_NAME --task-definition $NEW_TASK_DEF

# 8. Aguardar deployment
echo "Waiting for deployment to complete..."
aws ecs wait services-stable --cluster $CLUSTER_NAME --services $SERVICE_NAME

# Cleanup
rm -f task-def-temp.json task-def-new.json

echo "Deploy completed successfully!"
echo "Image deployed: $IMAGE_URI"
