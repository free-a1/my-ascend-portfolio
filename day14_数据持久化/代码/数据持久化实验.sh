#!/bin/bash
# 案例14：数据持久化（命名卷 vs Bind Mount；删除容器后数据仍在；匿名卷演示）
# 改动说明：原脚本以 sudo -i 交互执行；此处改为非交互 sudo。工作目录由 /home/ubuntu/day14
#          改为 $HOME/ascend/day14。最后一步“删除命名卷”默认注释保留数据（文档中演示其用法）。
set -e
WORK="$HOME/ascend/day14"
mkdir -p "$WORK" && cd "$WORK"

# 1. 宿主机数据集与读取脚本
cat > dataset.txt <<'EOF'
id,value
1,10
2,20
3,30
EOF
cat > read_data.py <<'EOF'
import sys
path = sys.argv[1]
with open(path, "r", encoding="utf-8") as f:
    data = f.read()
print("读取数据集:", path)
print(data, end="")
EOF
echo "===== 1) 宿主机数据集 dataset.txt ====="
cat dataset.txt

echo "===== 2) 创建命名卷并查看 ====="
sudo docker volume rm day14-data >/dev/null 2>&1 || true
sudo docker volume create day14-data
sudo docker volume ls --format 'table {{.Driver}}\t{{.Name}}' | head -4
sudo docker volume inspect -f '挂载点: {{.Mountpoint}}' day14-data

echo "===== 3) 写容器：Bind Mount 宿主数据集 -> 写入命名卷 -> 容器内读取 ====="
sudo docker rm -f day14-writer >/dev/null 2>&1 || true
sudo docker run -d --name day14-writer -v day14-data:/data -v "$WORK:/src" python:3.11-slim sleep infinity
sudo docker exec day14-writer sh -c 'cat /src/dataset.txt > /data/dataset.txt'
sudo docker exec day14-writer python /src/read_data.py /data/dataset.txt

echo "===== 4) 删除写容器，新容器挂载同一命名卷再读（持久化证明）====="
sudo docker stop day14-writer >/dev/null
sudo docker rm day14-writer >/dev/null
sudo docker ps -a --format 'table {{.Names}}\t{{.Status}}' | head -3
sudo docker run --rm --name day14-reader -v day14-data:/data -v "$WORK:/src" \
  python:3.11-slim python /src/read_data.py /data/dataset.txt

echo "===== 5) 宿主机直接查看命名卷内数据（容器内外共享）====="
VOL="$(sudo docker volume inspect -f '{{.Mountpoint}}' day14-data)"
sudo cat "$VOL/dataset.txt"

echo "===== 6) 匿名卷演示（不指定卷名，Docker 自动创建）====="
sudo docker run -d --name day14-anon -v /data python:3.11-slim sleep infinity >/dev/null
sudo docker rm -f day14-anon >/dev/null
sudo docker volume ls -q | head -5

echo "===== 7) 清理命名卷用法（默认注释：删除后数据丢失）====="
echo "# sudo docker volume rm day14-data"
echo "===== 数据持久化实验完成 ====="