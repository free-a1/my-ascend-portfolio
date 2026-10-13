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
