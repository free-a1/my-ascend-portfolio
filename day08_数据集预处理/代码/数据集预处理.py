from pathlib import Path
import csv
import json
import re
import shutil
from collections import Counter

RAW_DIR = Path("dataset/raw")
OUT_DIR = Path("dataset/processed")
ANNO_CSV = Path("dataset/annotations.csv")
ANNO_JSON = Path("dataset/annotations.json")
IMG_EXTS = {".jpg", ".jpeg", ".png", ".bmp", ".webp"}


def safe_name(name: str) -> str:
    name = name.strip().lower()
    name = re.sub(r"[^\w\-]+", "_", name)
    return name.strip("_") or "unknown"


def is_image(p: Path) -> bool:
    return p.is_file() and p.suffix.lower() in IMG_EXTS


def main():
    if not RAW_DIR.exists():
        print(f"未找到 {RAW_DIR}，请先建 dataset/raw/类别名/图片")
        return

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    records = []
    counters = {}

    class_dirs = sorted([p for p in RAW_DIR.iterdir() if p.is_dir()])
    direct_images = sorted([p for p in RAW_DIR.iterdir() if is_image(p)])

    tasks = [(d, d.name) for d in class_dirs]
    if direct_images:
        tasks.append((RAW_DIR, "unknown"))

    for src_dir, raw_cls in tasks:
        cls = safe_name(raw_cls)
        out_cls_dir = OUT_DIR / cls
        out_cls_dir.mkdir(parents=True, exist_ok=True)

        if src_dir == RAW_DIR:
            images = direct_images
        else:
            images = sorted([p for p in src_dir.rglob("*") if is_image(p)])

        for img in images:
            counters[cls] = counters.get(cls, 0) + 1
            new_name = f"{cls}_{counters[cls]:04d}{img.suffix.lower()}"
            dst = out_cls_dir / new_name
            shutil.copy2(img, dst)

            records.append({
                "filename": new_name,
                "class": cls,
                "path": dst.as_posix(),
                "source": img.as_posix(),
                "size_bytes": img.stat().st_size,
            })

    fieldnames = ["filename", "class", "path", "source", "size_bytes"]

    with ANNO_CSV.open("w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(records)

    ANNO_JSON.write_text(
        json.dumps(records, ensure_ascii=False, indent=2),
        encoding="utf-8"
    )

    print(f"完成：{len(records)} 张图片")
    print("类别统计：", dict(Counter(r["class"] for r in records)))
    print(f"标注清单：{ANNO_CSV} / {ANNO_JSON}")


if __name__ == "__main__":
    main()