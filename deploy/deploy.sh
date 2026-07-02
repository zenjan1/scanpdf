#!/bin/bash
#=============================================================
# ScanPDF 部署脚本
# 服务器: ubuntu@jp.zenjan.store
#=============================================================
set -euo pipefail

DOMAIN="jp.zenjan.store"
EMAIL="admin@zenjan.store"
PROJECT_DIR="/home/ubuntu/scanpdf"
COMPOSE_FILE="$PROJECT_DIR/docker-compose.yml"

echo "========================================="
echo "  ScanPDF 部署到 $DOMAIN"
echo "========================================="

# 1. 系统更新和依赖安装
echo "[1/7] 安装系统依赖..."
sudo apt-get update -qq
sudo apt-get install -y -qq docker.io docker-compose-plugin git certbot

# 2. 拉取最新代码
echo "[2/7] 拉取最新代码..."
cd "$PROJECT_DIR"
git pull origin main

# 3. 获取 SSL 证书（首次部署）
if [ ! -f "$PROJECT_DIR/deploy/ssl/fullchain.pem" ]; then
    echo "[3/7] 申请 SSL 证书..."
    sudo certbot certonly --standalone -d "$DOMAIN" --email "$EMAIL" --agree-tos --non-interactive
    sudo cp /etc/letsencrypt/live/$DOMAIN/fullchain.pem "$PROJECT_DIR/deploy/ssl/"
    sudo cp /etc/letsencrypt/live/$DOMAIN/privkey.pem "$PROJECT_DIR/deploy/ssl/"
    sudo chown -R ubuntu:ubuntu "$PROJECT_DIR/deploy/ssl/"
else
    echo "[3/7] SSL 证书已存在，跳过"
fi

# 4. 环境变量
echo "[4/7] 配置环境变量..."
if [ ! -f "$PROJECT_DIR/server/.env" ]; then
    SECRET=$(openssl rand -hex 32)
    cat > "$PROJECT_DIR/server/.env" <<EOF
DATABASE_URL=postgresql://scanpdf:scanpdf_password@postgres:5432/scanpdf
REDIS_URL=redis://redis:6379/0
SECRET_KEY=$SECRET
UPLOAD_DIR=/data/scanpdf/uploads
DEBUG=false
EOF
fi

# 5. 创建必要目录
echo "[5/7] 创建目录..."
mkdir -p "$PROJECT_DIR/server/data/uploads"
mkdir -p "$PROJECT_DIR/deploy/ssl"

# 6. 构建并启动服务
echo "[6/7] 构建并启动 Docker 容器..."
cd "$PROJECT_DIR"
docker compose down --remove-orphans 2>/dev/null || true
docker compose build --no-cache
docker compose up -d

# 7. 等待服务就绪
echo "[7/7] 等待服务启动..."
sleep 10

# 健康检查
if curl -sf https://$DOMAIN/health > /dev/null 2>&1; then
    echo "✅ 部署成功！"
    echo "   API: https://$DOMAIN/api/v1/"
    echo "   文档: https://$DOMAIN/api/v1/docs"
else
    echo "⚠️  服务可能还在启动中，请稍后检查..."
    echo "   查看日志: docker compose logs -f backend"
fi

echo ""
echo "========================================="
echo "  常用命令"
echo "========================================="
echo "  查看日志:    docker compose logs -f"
echo "  重启服务:    docker compose restart"
echo "  停止服务:    docker compose down"
echo "  更新证书:    sudo certbot renew"
echo "========================================="
