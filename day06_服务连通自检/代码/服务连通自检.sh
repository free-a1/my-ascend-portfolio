cat > service_check.sh <<'EOF'
#!/bin/bash
TARGET_IP="127.0.0.1"
TARGET_PORT="8080"

echo "===== 服务连通自检报告 ====="
echo "--- 1. 接口信息：ip addr ---"
ip addr
echo "--- 接口信息：ip link ---"
ip link

echo "--- 2. TCP 监听端口：ss -tlnp ---"
ss -tlnp

echo "--- 3. 目标 IP 连通性：ping -c 2 $TARGET_IP ---"
ping -c 2 "$TARGET_IP"

echo "--- 4. 推理服务 HTTP 探测：curl ---"
curl -s -o /dev/null -w "HTTP状态码: %{http_code}\n" --max-time 5 "http://$TARGET_IP:$TARGET_PORT/"
echo "说明：HTTP状态码 200/404 等表示能连通；000 表示连接失败。"
echo "===== 报告结束 ====="
EOF

bash service_check.sh > service_check_report.txt
cat service_check_report.txt