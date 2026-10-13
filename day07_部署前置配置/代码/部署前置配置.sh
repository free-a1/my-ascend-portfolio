#!/bin/bash
# 案例7：部署前置配置（pip/apt 国内镜像源 + ufw 防火墙端口开放）
set -e

sudo bash <<'EOF'
# 1. 配置 pip 国内镜像源（写入 /etc/pip.conf 对所有用户生效）
cat > /etc/pip.conf <<'PIP'
[global]
index-url = https://pypi.tuna.tsinghua.edu.cn/simple
PIP
echo "pip 源已配置：/etc/pip.conf"

# 2. 配置 apt 国内镜像源（发行版代号自动探测，勿写死 jammy）
CODENAME=$(. /etc/os-release && echo "$VERSION_CODENAME")
cp -a /etc/apt/sources.list /etc/apt/sources.list.bak2 2>/dev/null || true
mv /etc/apt/sources.list.d/ubuntu.sources /etc/apt/sources.list.d/ubuntu.sources.disabled 2>/dev/null || true
cat > /etc/apt/sources.list <<APT
deb http://mirrors.aliyun.com/ubuntu/ $CODENAME main restricted universe multiverse
deb http://mirrors.aliyun.com/ubuntu/ $CODENAME-updates main restricted universe multiverse
deb http://mirrors.aliyun.com/ubuntu/ $CODENAME-backports main restricted universe multiverse
deb http://mirrors.aliyun.com/ubuntu/ $CODENAME-security main restricted universe multiverse
APT
apt update

# 3. ufw 开放推理服务常用端口，并设置开机自启
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 8080/tcp
ufw --force enable
systemctl enable ufw
systemctl start ufw 2>/dev/null || true

# 4. 验证
pip config list
ufw status verbose
EOF

echo "===== 部署前置配置完成 ====="
