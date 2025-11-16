#!/bin/bash

# Script para corrigir a instância ECS
echo "Corrigindo configuração da instância ECS..."

# 1. Parar a instância atual
echo "Parando instância atual..."
aws ec2 stop-instances --instance-ids i-04d251c41c5aba19b --region us-east-1

# 2. Aguardar a instância parar
echo "Aguardando instância parar..."
aws ec2 wait instance-stopped --instance-ids i-04d251c41c5aba19b --region us-east-1

# 3. Criar user data para configurar ECS Agent
cat > user-data.txt << 'EOF'
#!/bin/bash
yum update -y
yum install -y ecs-init
echo "ECS_CLUSTER=cluster-bia" >> /etc/ecs/ecs.config
systemctl enable ecs
systemctl start ecs
EOF

# 4. Modificar a instância para incluir user data
echo "Modificando configuração da instância..."
aws ec2 modify-instance-attribute \
  --instance-id i-04d251c41c5aba19b \
  --user-data file://user-data.txt \
  --region us-east-1

# 5. Iniciar a instância
echo "Iniciando instância..."
aws ec2 start-instances --instance-ids i-04d251c41c5aba19b --region us-east-1

# 6. Aguardar a instância iniciar
echo "Aguardando instância iniciar..."
aws ec2 wait instance-running --instance-ids i-04d251c41c5aba19b --region us-east-1

echo "Configuração concluída! Aguarde alguns minutos para o ECS Agent se registrar no cluster."
