#!/bin/bash
# 案例3：远程任务守护（SSH 免密 + nohup 后台任务 + 系统信息查看）

# 0. 确保 sshd 在运行（WSL/最小化系统可能未启动）
if ! pgrep -x sshd >/dev/null; then
  sudo service ssh start 2>/dev/null || sudo /usr/sbin/sshd
  sleep 1
fi

# 1. 配置 SSH 免密登录（本机模拟远程 localhost；幂等：已有密钥则不覆盖）
mkdir -p ~/.ssh
chmod 700 ~/.ssh
if [ ! -f ~/.ssh/id_rsa ]; then
  ssh-keygen -t rsa -N "" -f ~/.ssh/id_rsa -q
  echo "已生成新密钥 ~/.ssh/id_rsa"
else
  echo "~/.ssh/id_rsa 已存在，复用现有密钥"
fi
grep -qf ~/.ssh/id_rsa.pub ~/.ssh/authorized_keys 2>/dev/null || cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
ssh -o StrictHostKeyChecking=accept-new localhost "echo 免密登录成功"

# 2. 用 cat 编写极简训练脚本
cat > ~/train.sh <<'EOF'
#!/bin/bash
echo "训练开始 $(date '+%T')"
sleep 10
echo "训练结束 $(date '+%T')"
EOF
chmod +x ~/train.sh

# 3. 用 scp 模拟传输到远程主机
scp ~/train.sh localhost:~/train_remote.sh

# 4. 用 ssh + nohup + & 模拟远程提交后台任务，并输出 PID
TRAIN_PID=$(ssh localhost "nohup ~/train_remote.sh > ~/train.log 2>&1 & echo \$!")
echo "后台训练任务 PID：$TRAIN_PID"

# 5. 查看进程与后台任务（ps -ef 输出太长，过滤训练相关进程）
ps -ef | grep -E "train_remote|$TRAIN_PID" | grep -v grep
jobs

# 6. 等待训练结束再查看日志
while kill -0 "$TRAIN_PID" 2>/dev/null; do sleep 2; done
echo "===== 训练日志 ====="
cat ~/train.log

# 7. 结束进程演示（训练已结束，此处仅说明用法）
# kill $TRAIN_PID   # 如需中途停止后台训练，用 kill + PID

# 8. 系统信息查看
uname -a
df -h /
du -sh ~
free -h
if command -v nvidia-smi >/dev/null 2>&1; then
  nvidia-smi
elif command -v npu-smi >/dev/null 2>&1; then
  npu-smi info
else
  echo "本机为纯 CPU 环境（WSL Ubuntu），无 nvidia-smi/npu-smi；GPU 机器上用 nvidia-smi，昇腾机器上用 npu-smi info"
fi
