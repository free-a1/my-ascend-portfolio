#!/bin/bash
# 案例11：容器环境搭建（Docker Engine 检查 + 国内镜像加速器 + 镜像操作 images/tag/rmi）
# 改动说明：原脚本以 sudo -i 进入交互 root 逐条手工执行；此处改为非交互 sudo 顺序执行，
#          便于自动化运行与留证（NOPASSWD sudo 已配置）。pytorch 镜像体积过大（数 GB），
#          改为拉取轻量 python:3.11-slim 完成等价的镜像管理演示，文档中已注明。
set -e

echo "===== 1. Docker Engine 版本与运行状态 ====="
sudo docker version --format 'Client {{.Client.Version}} / Server {{.Server.Version}}'
sudo docker info --format '存储驱动: {{.Driver}}  容器: {{.Containers}}  镜像: {{.Images}}'

echo "===== 2. 配置国内镜像加速器 /etc/docker/daemon.json ====="
sudo mkdir -p /etc/docker
sudo bash -c "cat > /etc/docker/daemon.json <<'EOF'
{
  \"registry-mirrors\": [
    \"https://docker.m.daocloud.io\",
    \"https://mirror.baidubce.com\"
  ]
}
EOF"
cat /etc/docker/daemon.json

echo "===== 3. systemctl 管理 Docker ====="
sudo systemctl daemon-reload
sudo systemctl restart docker
sleep 3
sudo systemctl enable docker
sudo systemctl is-active docker
sudo docker info --format 'Registry Mirrors: {{.RegistryConfig.Mirrors}}'

echo "===== 4. 拉取镜像 python:3.11-slim ====="
sudo docker pull python:3.11-slim

echo "===== 5. 镜像操作：images / tag / rmi ====="
sudo docker images --format 'table {{.Repository}}\t{{.Tag}}\t{{.Size}}'
sudo docker tag python:3.11-slim python:day11-test
echo "--- tag 后 ---"
sudo docker images --format 'table {{.Repository}}\t{{.Tag}}\t{{.Size}}' | grep -E 'REPOSITORY|python'
sudo docker rmi python:day11-test
echo "--- rmi 后 ---"
sudo docker images --format 'table {{.Repository}}\t{{.Tag}}\t{{.Size}}' | grep -E 'REPOSITORY|python'

echo "===== 6. 验证汇总 ====="
sudo docker info --format '镜像加速器: {{.RegistryConfig.Mirrors}}'
echo "docker 服务状态: $(sudo systemctl is-active docker)"
sudo docker images --format 'table {{.Repository}}\t{{.Tag}}\t{{.Size}}' | grep python
echo "===== 容器环境搭建完成 ====="