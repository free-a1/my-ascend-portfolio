#!/bin/bash
# 案例13：封装推理服务（app.py + Dockerfile：CMD / ENTRYPOINT / 多阶段构建 三种写法对比）
# 改动说明：原脚本以 sudo -i 交互执行；此处改为非交互 sudo 顺序执行便于留证。
#          基础镜像由 pytorch/pytorch:latest（数 GB）改为 python:3.11-slim，推理计算等价改写为纯 Python。
set -e
WORK="$HOME/ascend/day13"
mkdir -p "$WORK" && cd "$WORK"

# 1. 推理程序 app.py
cat > app.py <<'EOF'
import os

model_name = os.environ.get("MODEL_NAME", "unknown")
x = [1.0, 2.0, 3.0]
w = [[0.1, 0.4], [0.2, 0.5], [0.3, 0.6]]
y = [round(sum(xi * wi for xi, wi in zip(x, col)), 4) for col in zip(*w)]
print("模型名称:", model_name)
print("输入:", x)
print("推理输出:", y)
EOF

# 2. 三个 Dockerfile：CMD / ENTRYPOINT / 多阶段构建
cat > Dockerfile <<'EOF'
FROM python:3.11-slim
ENV MODEL_NAME=day13-infer
WORKDIR /workspace
COPY app.py .
EXPOSE 8000
CMD ["python", "app.py"]
EOF

cat > Dockerfile.entrypoint <<'EOF'
FROM python:3.11-slim
ENV MODEL_NAME=day13-entry
WORKDIR /workspace
COPY app.py .
ENTRYPOINT ["python", "app.py"]
EOF

cat > Dockerfile.multi <<'EOF'
FROM python:3.11-slim AS builder
WORKDIR /workspace
COPY app.py .
RUN python -c "print('builder 阶段检查 app.py 存在')"
FROM python:3.11-slim
ENV MODEL_NAME=day13-multi
WORKDIR /workspace
COPY --from=builder /workspace/app.py .
CMD ["python", "app.py"]
EOF
echo "===== 1) 镜像上下文文件 ====="
ls -1

echo "===== 2) 构建并运行 CMD 版镜像 ====="
sudo docker build -q -t day13-infer:latest . >/dev/null 2>&1
sudo docker run --rm day13-infer:latest

echo "===== 3) 构建并运行 ENTRYPOINT 版镜像 ====="
sudo docker build -q -t day13-entry:latest -f Dockerfile.entrypoint . >/dev/null 2>&1
sudo docker run --rm day13-entry:latest

echo "===== 4) 构建并运行多阶段构建版镜像 ====="
sudo docker build -q -t day13-multi:latest -f Dockerfile.multi . >/dev/null 2>&1
sudo docker run --rm day13-multi:latest

echo "===== 5) 本地镜像列表 ====="
sudo docker images --format 'table {{.Repository}}\t{{.Tag}}\t{{.Size}}'
echo "===== 封装推理服务完成 ====="