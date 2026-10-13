#!/bin/bash
# 案例18：资源监控脚本——采集系统负载/内存/磁盘与可选 GPU 指标，输出 CSV 报表
set -e

# 创建监控脚本
cat > monitor_infer.sh <<'EOF'
#!/bin/bash
# 推理资源监控：采集系统负载、内存、磁盘，以及可选的 NVIDIA GPU 指标

out="resource_report.csv"   # 输出报表文件
echo "time,load,mem_used_mb,mem_total_mb,disk_used,gpu_util,gpu_mem_used_mb,gpu_mem_total_mb,gpu_temp_c" > "$out"

# 循环采集 10 次，每次间隔 1 秒
for i in $(seq 1 10); do
  t=$(date '+%F %T')                     # 当前时间
  load=$(cut -d' ' -f1 /proc/loadavg)    # 1 分钟平均负载
  mem=$(free -m | awk '/Mem:/{print $3","$2}')  # 已用内存,总内存 (MB)
  disk=$(df -h / | awk 'NR==2{print $5}')       # 根分区使用率

  # 若存在 nvidia-smi，则采集 GPU 利用率、显存、温度；否则填 NA
  if command -v nvidia-smi >/dev/null 2>&1; then
    gpu=$(nvidia-smi --query-gpu=utilization.gpu,memory.used,memory.total,temperature.gpu \
          --format=csv,noheader,nounits | head -1 | tr -d ' ')
  else
    gpu="NA,NA,NA,NA"
  fi

  echo "$t,$load,$mem,$disk,$gpu" >> "$out"   # 追加一行到 CSV
  sleep 1
done

echo "报表已生成：$out"
EOF

# 赋予执行权限并运行
chmod +x monitor_infer.sh
./monitor_infer.sh

# 查看生成的资源报表
cat resource_report.csv