#!/bin/bash
set -e
IMAGE=infer-service:day19
echo "[start.sh] 构建镜像 $IMAGE"
docker build --network=host -t $IMAGE .
docker rm -f day19-svc >/dev/null 2>&1 || true
echo "[start.sh] 启动容器（-p 8000:8000）"
docker run -d --name day19-svc -p 8000:8000 $IMAGE >/dev/null
for i in $(seq 1 30); do curl -sf http://127.0.0.1:8000/health >/dev/null 2>&1 && break; sleep 1; done
echo "[start.sh] 健康检查 /health :"
curl -s http://127.0.0.1:8000/health; echo
echo "[start.sh] 推理测试 /predict :"
curl -s -X POST http://127.0.0.1:8000/predict -H 'Content-Type: application/json' -d '{"r":190,"g":55,"b":45}'; echo
echo "[start.sh] 清理容器"
docker rm -f day19-svc >/dev/null
