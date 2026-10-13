#!/bin/bash
# 案例15：多容器部署（自定义网络 + 推理容器 + 前端容器互联，宿主机/容器内双向验证）
# 改动说明：原脚本以 sudo -i 交互执行；此处改为非交互 sudo，工作目录改到 $HOME/ascend/day15，
#          -d -it 保活改为 sleep infinity。docker-compose.yml 仅生成展示（不实际 compose up）。
set -e
WORK="$HOME/ascend/day15"
mkdir -p "$WORK" && cd "$WORK"

echo "===== 1) 创建自定义网络 day15-net ====="
sudo docker network rm day15-net >/dev/null 2>&1 || true
sudo docker network create day15-net

echo "===== 2) 启动推理容器 infer（-p 5000:5000）====="
sudo docker rm -f infer frontend >/dev/null 2>&1 || true
sudo docker run -d --name infer --network day15-net -p 5000:5000 python:3.11-slim sleep infinity

sudo docker exec -i infer sh -c 'mkdir -p /app && cat > /app/infer_server.py' <<'EOF'
import json
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/infer":
            body = json.dumps({"result": 1.4, "msg": "infer ok"}).encode()
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)
        else:
            self.send_response(404)
            self.end_headers()
    def log_message(self, *a):
        pass

ThreadingHTTPServer(("0.0.0.0", 5000), Handler).serve_forever()
EOF
sudo docker exec -d infer python /app/infer_server.py

echo "===== 3) 启动前端容器 frontend（-p 8080:8080）====="
sudo docker run -d --name frontend --network day15-net -p 8080:8080 python:3.11-slim sleep infinity

sudo docker exec -i frontend sh -c 'mkdir -p /app && cat > /app/frontend_server.py' <<'EOF'
import urllib.request
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        try:
            with urllib.request.urlopen("http://infer:5000/infer", timeout=5) as r:
                data = r.read().decode()
        except Exception as e:
            data = "前端请求推理服务失败: " + str(e)
        body = ("前端调用推理服务结果:\n" + data + "\n").encode()
        self.send_response(200)
        self.send_header("Content-Type", "text/plain; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)
    def log_message(self, *a):
        pass

ThreadingHTTPServer(("0.0.0.0", 8080), Handler).serve_forever()
EOF
sudo docker exec -d frontend python /app/frontend_server.py
sleep 2

echo "===== 4) 多容器运行状态 docker ps ====="
sudo docker ps --format 'table {{.Names}}\t{{.Ports}}\t{{.Status}}'

echo "===== 5) 自定义网络中的容器与 IP（验证互联）====="
sudo docker network inspect -f '网络 {{.Name}} 容器: {{range .Containers}}{{.Name}}({{.IPv4Address}}) {{end}}' day15-net

echo "===== 6) 宿主机访问前端 8080，前端再调用后端推理 ====="
python3 -c "import urllib.request; print(urllib.request.urlopen('http://localhost:8080', timeout=5).read().decode())"

echo "===== 7) 前端容器内直接访问推理服务（容器间通信）====="
sudo docker exec frontend python -c "import urllib.request; print(urllib.request.urlopen('http://infer:5000/infer', timeout=5).read().decode())"

echo "===== 8) 生成 docker-compose.yml（编排示例，仅展示）====="
cat > docker-compose.yml <<'EOF'
services:
  infer:
    image: python:3.11-slim
    command: python /app/infer_server.py
    ports:
      - "5000:5000"
  frontend:
    image: python:3.11-slim
    command: python /app/frontend_server.py
    ports:
      - "8080:8080"
EOF
cat docker-compose.yml

echo "===== 9) 清理：停止删除容器与网络 ====="
sudo docker stop infer frontend >/dev/null
sudo docker rm infer frontend >/dev/null
sudo docker network rm day15-net >/dev/null
echo "===== 多容器部署完成 ====="