import random, json, os
from pathlib import Path

# 数据目录可移植：默认 ~/project/data，可用环境变量 PROJ_DATA 覆盖
DATA_DIR = Path(os.environ.get("PROJ_DATA", Path.home() / "project" / "data"))
DATA_DIR.mkdir(parents=True, exist_ok=True)

random.seed(7)


def make_ppm(path, base, noise=25):
    w, h = 32, 32
    with open(path, "wb") as f:
        f.write(f"P6\n{w} {h}\n255\n".encode())
        for _ in range(w * h):
            px = [max(0, min(255, c + random.randint(-noise, noise))) for c in base]
            f.write(bytes(px))


make_ppm(str(DATA_DIR / "train_red.ppm"), (200, 40, 40))
make_ppm(str(DATA_DIR / "train_blue.ppm"), (40, 60, 200))
make_ppm(str(DATA_DIR / "test1.ppm"), (190, 55, 45))
make_ppm(str(DATA_DIR / "test2.ppm"), (50, 70, 190))
print("数据集生成完成：", DATA_DIR)