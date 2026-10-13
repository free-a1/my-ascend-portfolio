import json, os
from pathlib import Path

# 数据目录可移植：默认 ~/project/data，可用环境变量 PROJ_DATA 覆盖
DATA_DIR = Path(os.environ.get("PROJ_DATA", Path.home() / "project" / "data"))


def read_ppm(path):
    with open(path, "rb") as f:
        assert f.readline().strip() == b"P6"
        f.readline()
        f.readline()
        data = f.read()
    px = [(data[i], data[i+1], data[i+2]) for i in range(0, len(data), 3)]
    return px

model = {}
for label, path in [("red", DATA_DIR / "train_red.ppm"),
                    ("blue", DATA_DIR / "train_blue.ppm")]:
    px = read_ppm(str(path))
    n = len(px)
    model[label] = [round(sum(p[i] for p in px) / n) for i in range(3)]

with open(DATA_DIR / "model.json", "w") as f:
    json.dump(model, f)
print("模型权重:", model)