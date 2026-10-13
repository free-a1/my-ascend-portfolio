#!/bin/bash
# 案例19：端到端交付——整合 Dockerfile + 推理脚本 + 部署说明，构建并运行一个可交付的推理服务项目
# 模拟 FAE 交付：交付物 = 可运行代码 + 环境定义(Dockerfile/requirements) + 部署说明(README) + 一键启动(start.sh)
set -e
WORK="$HOME/ascend/day19"
PKG="$WORK/inference-service"
rm -rf "$PKG"
mkdir -p "$PKG/app" && cd "$PKG"

# 1. 推理服务代码
cat > app/infer.py <<'EOF'
"""端到端交付示例：极简颜色质心推理服务（Flask）。

模型来自 day17 的迷你 CV 训练结果（red/blue 两个类别质心），
提供 /health 健康检查与 /predict 推理接口。
"""
from flask import Flask, jsonify, request

app = Flask(__name__)

MODEL = {"red": (199, 40, 40), "blue": (40, 60, 200)}


@app.get("/health")
def health():
    return jsonify({"status": "ok", "model": "color-centroid", "classes": list(MODEL)})


@app.post("/predict")
def predict():
    data = request.get_json(silent=True) or {}
    try:
        px = (float(data["r"]), float(data["g"]), float(data["b"]))
    except (KeyError, TypeError, ValueError):
        return jsonify({"error": "需要 r/g/b 三个数值字段"}), 400

    dist = {k: sum((px[i] - v[i]) ** 2 for i in range(3)) ** 0.5 for k, v in MODEL.items()}
    best = min(dist, key=dist.get)
    score = round(1 - dist[best] / (sum(dist.values()) or 1.0), 4)
    return jsonify({"label": best, "score": score,
                    "distances": {k: round(v, 2) for k, v in dist.items()}})


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8000)
EOF

# 2. 依赖清单
cat > requirements.txt <<'EOF'
flask==3.0.3
EOF

# 3. Dockerfile（环境定义，一层层写清 FROM/WORKDIR/COPY/RUN/EXPOSE/CMD）
cat > Dockerfile <<'EOF'
FROM python:3.11-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt -i https://pypi.tuna.tsinghua.edu.cn/simple
COPY app/infer.py .
EXPOSE 8000
CMD ["python", "infer.py"]
EOF

# 4. 部署说明
cat > README.md <<'EOF'
# 推理服务交付包（inference-service）

极简颜色质心推理服务，用于演示 FAE 端到端交付。

## 目录
- app/infer.py       推理服务（Flask，/health 与 /predict）
- requirements.txt   依赖清单
- Dockerfile         镜像构建定义
- start.sh           一键构建 + 启动 + 验收

## 部署步骤
```bash
# 注：WSL 下 docker 构建容器的 DNS 常解析失败，用 --network=host 复用宿主机网络
docker build --network=host -t infer-service:day19 .
docker run -d --name day19-svc -p 8000:8000 infer-service:day19
```

## 接口
| 方法 | 路径 | 说明 |
|---|---|---|
| GET | /health | 健康检查，返回模型名与类别 |
| POST | /predict | 入参 {"r":190,"g":55,"b":45}，返回 {"label","score"} |

## 验收
```bash
curl http://127.0.0.1:8000/health
curl -X POST http://127.0.0.1:8000/predict -H 'Content-Type: application/json' -d '{"r":190,"g":55,"b":45}'
```
预期：/health 返回 status=ok；/predict 对红色样本返回 label=red。
EOF

# 5. 一键启动 + 验收脚本
cat > start.sh <<'EOF'
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
EOF
chmod +x start.sh

echo "===== 1) 交付包结构 ====="
find . -type f | sort

echo "===== 2) 构建镜像并启动服务（start.sh，含健康检查与推理验收）====="
sudo bash start.sh

echo "===== 3) 交付包最终清单 ====="
ls -l
echo "===== 端到端交付完成 ====="