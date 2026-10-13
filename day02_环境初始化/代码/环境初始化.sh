#!/bin/bash
# 案例2：环境初始化（建用户 / 配 sudo / apt 换国内源）
# 注意：init_env.sh 需要 root 权限执行
set -e

cat > init_env.sh <<'EOF'
#!/bin/bash
# 环境初始化脚本：建用户、配 sudo、apt 换国内源
# 必须用 sudo ./init_env.sh 执行

if [ "$(id -u)" -ne 0 ]; then
  echo "请以 root 运行：sudo ./init_env.sh"
  exit 1
fi

# 1. 用户与组：创建 fae 组和专用用户 fae（幂等：已存在则跳过）
groupadd -f fae
if id fae >/dev/null 2>&1; then
  echo "用户 fae 已存在，跳过创建"
else
  useradd -m -s /bin/bash -g fae fae
  echo "已创建用户 fae"
fi

# 2. 配置 sudo：加入 sudo 组，并写入 /etc/sudoers.d/fae
usermod -aG sudo fae
echo 'fae ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/fae
chown root:root /etc/sudoers.d/fae
chmod 440 /etc/sudoers.d/fae
visudo -cf /etc/sudoers.d/fae && echo "sudoers 配置校验通过"

# 3. apt 换国内源：先备份，再写入阿里云源（发行版代号自动探测，勿写死 jammy！）
CODENAME=$(. /etc/os-release && echo "$VERSION_CODENAME")
cp -a /etc/apt/sources.list /etc/apt/sources.list.bak 2>/dev/null || true
cp -a /etc/apt/sources.list.d/ubuntu.sources /etc/apt/sources.list.d/ubuntu.sources.bak 2>/dev/null || true
# 禁用官方 deb822 源文件，统一改用传统 sources.list，避免两个源混用
mv /etc/apt/sources.list.d/ubuntu.sources /etc/apt/sources.list.d/ubuntu.sources.disabled 2>/dev/null || true
cat > /etc/apt/sources.list <<SOURCES
deb https://mirrors.aliyun.com/ubuntu/ $CODENAME main restricted universe multiverse
deb https://mirrors.aliyun.com/ubuntu/ $CODENAME-updates main restricted universe multiverse
deb https://mirrors.aliyun.com/ubuntu/ $CODENAME-backports main restricted universe multiverse
deb https://mirrors.aliyun.com/ubuntu/ $CODENAME-security main restricted universe multiverse
SOURCES
echo "已换为阿里云源（发行版代号：$CODENAME）"

# 4. 更新软件包索引
apt update
EOF

chmod +x init_env.sh
sudo ./init_env.sh

echo "===== 验证 ====="
id fae
sudo -l -U fae
ls -l /etc/sudoers.d/fae
cat /etc/apt/sources.list
