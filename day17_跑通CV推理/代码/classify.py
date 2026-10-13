import json, time, sys, os
from pathlib import Path

# 数据目录可移植：默认 ~/project/data，可用环境变量 PROJ_DATA 覆盖
DATA_DIR = Path(os.environ.get("PROJ_DATA", Path.home() / "project" / "data"))


def read_ppm(path):
    with open(path, "rb") as f:
        f.readline(); f.readline(); f.readline()
        data = f.read()
    return [(data[i], data[i+1], data[i+2]) for i in range(0, len(data), 3)]

model = json.load(open(DATA_DIR / "model.json"))
img = read_ppm(sys.argv[1])
avg = [round(sum(p[i] for p in img) / len(img)) for i in range(3)]
t0 = time.time()
dist = {k: sum((avg[i] - v[i]) ** 2 for i in range(3)) ** 0.5 for k, v in model.items()}
best = min(dist, key=dist.get)
conf = 1 - dist[best] / (dist["red"] + dist["blue"])
ms = (time.time() - t0) * 1000
print(f"预测类别: {best}  置信度: {conf:.2f}  耗时: {ms:.2f} ms")