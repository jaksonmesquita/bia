#!/bin/bash

if [ $# -ne 2 ]; then
    echo "Uso: $0 <cluster-name> <service-name>"
    exit 1
fi

CLUSTER_NAME=$1
SERVICE_NAME=$2
REPOSITORY_URI="380278406175.dkr.ecr.us-east-1.amazonaws.com/bia"
COMMIT_HASH=$(git rev-parse --short=7 HEAD)

echo "=== Deploy BIA - Commit: $COMMIT_HASH ==="

# Login ECR
echo "[1/5] Login ECR..."
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 380278406175.dkr.ecr.us-east-1.amazonaws.com > /dev/null 2>&1

# Build (sem cache para ser mais rápido)
echo "[2/5] Build imagem..."
docker build --no-cache -t $REPOSITORY_URI:$COMMIT_HASH . > /dev/null 2>&1 &
BUILD_PID=$!

# Mostrar progresso
while kill -0 $BUILD_PID 2>/dev/null; do
    echo -n "."
    sleep 2
done
wait $BUILD_PID
echo " OK"

# Push
echo "[3/5] Push para ECR..."
docker push $REPOSITORY_URI:$COMMIT_HASH > /dev/null 2>&1

# Task Definition
echo "[4/5] Atualizando task definition..."
TASK_DEF_ARN=$(aws ecs describe-services --cluster $CLUSTER_NAME --services $SERVICE_NAME --query 'services[0].taskDefinition' --output text)
aws ecs describe-task-definition --task-definition $TASK_DEF_ARN --query 'taskDefinition' > /tmp/task-def.json
jq --arg uri "$REPOSITORY_URI:$COMMIT_HASH" '.containerDefinitions[0].image = $uri | del(.taskDefinitionArn, .revision, .status, .requiresAttributes, .placementConstraints, .compatibilities, .registeredAt, .registeredBy)' /tmp/task-def.json > /tmp/task-def-new.json
NEW_TASK_DEF=$(aws ecs register-task-definition --cli-input-json file:///tmp/task-def-new.json --query 'taskDefinition.taskDefinitionArn' --output text)

# Deploy
echo "[5/5] Deploy no ECS..."
aws ecs update-service --cluster $CLUSTER_NAME --service $SERVICE_NAME --task-definition $NEW_TASK_DEF > /dev/null

echo "✅ Deploy concluído! Imagem: $REPOSITORY_URI:$COMMIT_HASH"
rm -f /tmp/task-def*.json
