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
