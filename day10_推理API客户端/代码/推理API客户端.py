from __future__ import annotations

import argparse
import base64
import json
import random
import sys
import threading
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from typing import Any

import requests
from tqdm import tqdm


class InferenceError(Exception):
    """推理客户端基础异常。"""


class ApiResponseError(InferenceError):
    """接口返回异常或响应格式错误。"""


class InferenceClient:
    def __init__(
        self,
        base_url: str,
        timeout: float = 10.0,
        retries: int = 2,
        backoff: float = 0.5,
        session: requests.Session | None = None,
    ) -> None:
        self.base_url = base_url.rstrip("/")
        self.timeout = timeout
        self.retries = retries
        self.backoff = backoff
        self.session = session or requests.Session()
        self.history: list[dict[str, Any]] = []

    def __len__(self) -> int:
        return len(self.history)

    def __repr__(self) -> str:
        return (
            f"InferenceClient(base_url={self.base_url!r}, "
            f"timeout={self.timeout}, retries={self.retries}, calls={len(self)})"
        )

    def __str__(self) -> str:
        return f"推理客户端 -> {self.base_url}（已成功 {len(self)} 次）"

    def predict(self, image_path: Path) -> dict[str, Any]:
        url = f"{self.base_url}/predict"
        payload = {
            "filename": image_path.name,
            "image_b64": base64.b64encode(image_path.read_bytes()).decode("utf-8"),
        }

        last_exc: Exception | None = None
        for attempt in range(1, self.retries + 2):
            try:
                resp = self.session.post(url, json=payload, timeout=self.timeout)
                if resp.status_code >= 400:
                    raise ApiResponseError(
                        f"HTTP {resp.status_code}: {resp.text[:200]}"
                    )

                data = resp.json()
                if not isinstance(data, dict) or "predictions" not in data:
                    raise ApiResponseError(f"响应缺少 predictions 字段: {data}")

                self.history.append(data)
                return data

            except (requests.Timeout, requests.ConnectionError, ValueError, ApiResponseError) as e:
                last_exc = e
                if attempt <= self.retries:
                    time.sleep(self.backoff * attempt)
                else:
                    raise InferenceError(f"{image_path.name} 请求失败: {e}") from e

        raise InferenceError(f"{image_path.name} 请求失败: {last_exc}")


class MockHandler(BaseHTTPRequestHandler):
    """本地模拟推理接口，仅用于演示 requests + 异常 + tqdm 流程。"""

    def do_POST(self) -> None:
        if self.path != "/predict":
            self.send_error(404, "Not Found")
            return

        length = int(self.headers.get("Content-Length", 0))
        body = self.rfile.read(length)
        try:
            req = json.loads(body.decode("utf-8"))
        except Exception:
            req = {}

        filename = req.get("filename", "unknown")
        labels = ["cat", "dog", "person", "car"]
        predictions = [
            {
                "label": random.choice(labels),
                "score": round(random.uniform(0.50, 0.99), 4),
                "bbox": [10, 20, 100, 80],
            }
            for _ in range(random.randint(1, 3))
        ]

        data = {"filename": filename, "predictions": predictions}
        payload = json.dumps(data, ensure_ascii=False).encode("utf-8")

        self.send_response(200)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(payload)))
        self.end_headers()
        self.wfile.write(payload)

    def log_message(self, *args: Any) -> None:
        pass


def start_mock_server(host: str = "127.0.0.1", port: int = 0) -> ThreadingHTTPServer:
    server = ThreadingHTTPServer((host, port), MockHandler)
    thread = threading.Thread(target=server.serve_forever, daemon=True)
    thread.start()
    return server


def collect_images(root: Path) -> list[Path]:
    exts = {".jpg", ".jpeg", ".png", ".bmp", ".webp"}
    if root.is_file():
        return [root] if root.suffix.lower() in exts else []
    if not root.exists():
        return []
    return sorted(p for p in root.rglob("*") if p.is_file() and p.suffix.lower() in exts)


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="推理 API 客户端：requests + 异常处理 + tqdm")
    parser.add_argument("--input", type=Path, default=Path("images"), help="图片目录或单张图片")
    parser.add_argument("--base-url", default=None, help="真实推理服务地址，如 http://127.0.0.1:8000")
    parser.add_argument("--mock", action="store_true", help="启动本地模拟接口，便于离线跑通")
    parser.add_argument("--output", type=Path, default=Path("inference_results.json"))
    parser.add_argument("--timeout", type=float, default=10.0)
    parser.add_argument("--retries", type=int, default=2)
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv)

    server: ThreadingHTTPServer | None = None
    if args.mock:
        server = start_mock_server()
        host, port = server.server_address[:2]
        base_url = f"http://{host}:{port}"
        print(f"Mock 推理服务已启动: {base_url}")
    else:
        if not args.base_url:
            print("非 --mock 模式必须提供 --base-url", file=sys.stderr)
            return 2
        base_url = args.base_url

    images = collect_images(args.input)
    if not images:
        print(f"未找到图片: {args.input}", file=sys.stderr)
        if server:
            server.shutdown()
        return 1

    client = InferenceClient(base_url, timeout=args.timeout, retries=args.retries)
    print(client)

    results: list[dict[str, Any]] = []
    errors: list[dict[str, str]] = []

    try:
        for img in tqdm(images, desc="推理中", unit="img"):
            try:
                data = client.predict(img)
                results.append({"image": img.as_posix(), **data})
            except InferenceError as e:
                errors.append({"image": img.as_posix(), "error": str(e)})

        output = {
            "base_url": base_url,
            "total": len(images),
            "ok": len(results),
            "failed": len(errors),
            "results": results,
            "errors": errors,
        }

        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(
            json.dumps(output, ensure_ascii=False, indent=2),
            encoding="utf-8",
        )

        print(f"完成：成功 {len(results)} / 失败 {len(errors)} -> {args.output}")
        print(f"客户端成功调用次数: {len(client)}")
        return 0

    finally:
        client.session.close()
        if server:
            server.shutdown()


if __name__ == "__main__":
    sys.exit(main())