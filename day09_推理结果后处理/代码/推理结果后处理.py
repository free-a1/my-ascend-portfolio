from pathlib import Path
import argparse
import csv
import json
import sys
from collections import Counter
from statistics import mean


def load_predictions(path: Path):
    data = json.loads(path.read_text(encoding="utf-8"))
    if isinstance(data, dict):
        records = data.get("predictions", data.get("data", []))
    else:
        records = data
    if not isinstance(records, list):
        raise ValueError("JSON 顶层应为 list，或包含 predictions/data 列表")
    return records


def normalize(records, threshold=0.5, topk=None):
    rows = []
    for item in records:
        if not isinstance(item, dict):
            continue

        image_id = str(
            item.get("image_id")
            or item.get("id")
            or item.get("filename")
            or "unknown"
        )
        preds = item.get("predictions") or item.get("detections") or []
        if not isinstance(preds, list):
            continue

        filtered = []
        for p in preds:
            if not isinstance(p, dict):
                continue
            score = float(p.get("score", 0.0))
            if score >= threshold:
                filtered.append(p)

        filtered.sort(key=lambda p: float(p.get("score", 0.0)), reverse=True)
        if topk is not None:
            filtered = filtered[:topk]

        for rank, p in enumerate(filtered, 1):
            bbox = p.get("bbox") or p.get("box") or [None, None, None, None]
            if isinstance(bbox, (list, tuple)) and len(bbox) == 4:
                x, y, w, h = bbox
            else:
                x = y = w = h = None

            rows.append({
                "image_id": image_id,
                "rank": rank,
                "label": str(p.get("label") or p.get("class") or "unknown"),
                "score": round(float(p.get("score", 0.0)), 6),
                "x": x,
                "y": y,
                "w": w,
                "h": h,
            })
    return rows


def summarize(rows):
    by_label = Counter(r["label"] for r in rows)
    scores = [r["score"] for r in rows]
    return {
        "total_images": len({r["image_id"] for r in rows}),
        "total_boxes": len(rows),
        "by_label": dict(by_label.most_common()),
        "avg_score": round(mean(scores), 6) if scores else None,
        "max_score": max(scores) if scores else None,
        "min_score": min(scores) if scores else None,
    }


def write_csv(rows, path: Path):
    path.parent.mkdir(parents=True, exist_ok=True)
    fieldnames = ["image_id", "rank", "label", "score", "x", "y", "w", "h"]
    with path.open("w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)


def write_markdown(rows, summary, path: Path):
    path.parent.mkdir(parents=True, exist_ok=True)
    lines = []
    lines.append("# 推理结果后处理报表\n")
    lines.append("## 摘要\n")
    lines.append(f"- 图片数：{summary['total_images']}")
    lines.append(f"- 检测框数：{summary['total_boxes']}")
    lines.append(f"- 平均置信度：{summary['avg_score']}")
    lines.append(f"- 类别统计：{json.dumps(summary['by_label'], ensure_ascii=False)}\n")
    lines.append("## 明细\n")
    lines.append("| image_id | rank | label | score | bbox |")
    lines.append("|---|---:|---|---:|---|")
    for r in rows:
        bbox = f"({r['x']}, {r['y']}, {r['w']}, {r['h']})"
        lines.append(
            f"| {r['image_id']} | {r['rank']} | {r['label']} | {r['score']:.4f} | {bbox} |"
        )
    path.write_text("\n".join(lines), encoding="utf-8")


def parse_args(argv=None):
    parser = argparse.ArgumentParser(description="读取 JSON 推理输出并生成报表")
    parser.add_argument("--input", type=Path, default=Path("inference.json"))
    parser.add_argument("--output-dir", type=Path, default=Path("reports"))
    parser.add_argument("--threshold", type=float, default=0.5)
    parser.add_argument("--topk", type=int, default=None)
    return parser.parse_args(argv)


def main(argv=None):
    args = parse_args(argv)

    records = load_predictions(args.input)
    rows = normalize(records, threshold=args.threshold, topk=args.topk)
    summary = summarize(rows)

    csv_path = args.output_dir / "report.csv"
    md_path = args.output_dir / "report.md"
    json_path = args.output_dir / "summary.json"

    write_csv(rows, csv_path)
    write_markdown(rows, summary, md_path)
    json_path.parent.mkdir(parents=True, exist_ok=True)
    json_path.write_text(
        json.dumps(summary, ensure_ascii=False, indent=2),
        encoding="utf-8"
    )

    print(f"完成：{summary['total_boxes']} 个框，{summary['total_images']} 张图")
    print(f"报表：{csv_path} / {md_path} / {json_path}")
    return 0


if __name__ == "__main__":
    sys.exit(main())