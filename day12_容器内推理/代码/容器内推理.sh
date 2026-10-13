#!/bin/bash
# 案例12：容器内推理（挂载宿主目录 -> 后台启动容器 -> exec 进容器执行推理脚本 -> 生命周期管理）
# 改动说明：-d -it 交互保活改为 sleep infinity（自动化场景无 TTY）；pytorch/pytorch:latest
#          （数 GB）改为 python:3.11-slim，torch 张量乘法等价改写为纯 Python 矩阵乘，语义一致。
set -e
WORK="$HOME/ascend/day12"
mkdir -p "$WORK" && cd "$WORK"

# 1. 准备推理脚本
cat > infer.py <<'EOF'
# 容器内推理演示：3x1 输入向量与 3x2 权重矩阵的前向计算
# （原 torch 版 x @ w 的等价纯 Python 实现，避免拉取数 GB 的 pytorch 镜像）
x = [1.0, 2.0, 3.0]
w = [[0.1, 0.4], [0.2, 0.5], [0.3, 0.6]]
y = [round(sum(xi * wi for xi, wi in zip(x, col)), 4) for col in zip(*w)]
print("输入:", x)
print("推理输出:", y)
EOF
echo "推理脚本 infer.py 已生成:"
cat infer.py

# 2. 启动推理容器：后台运行 + 挂载宿主目录
sudo docker rm -f day12-infer >/dev/null 2>&1 || true
echo "===== 1) 启动推理容器（-d 后台 + -v 挂载宿主目录）====="
sudo docker run -d --name day12-infer -v "$WORK:/workspace" python:3.11-slim sleep infinity

# 3. 查看容器生命周期状态
echo "===== 2) 容器状态（docker ps / ps -a）====="
sudo docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}'
sudo docker ps -a --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}'

# 4. exec 进入容器运行 Python 推理脚本
echo "===== 3) exec 进入容器执行推理 ====="
sudo docker exec day12-infer python /workspace/infer.py

# 5. 生命周期管理演示：stop / start / restart / rm
echo "===== 4) 生命周期管理 stop / start / restart / rm ====="
sudo docker stop day12-infer >/dev/null
sudo docker start day12-infer >/dev/null
sudo docker restart day12-infer >/dev/null
sudo docker ps --format 'table {{.Names}}\t{{.Status}}'
sudo docker stop day12-infer >/dev/null
sudo docker rm day12-infer >/dev/null
echo "--- 销毁后 docker ps -a ---"
sudo docker ps -a --format 'table {{.Names}}\t{{.Status}}'
echo "===== 容器内推理完成 ====="