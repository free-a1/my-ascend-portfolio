#!/bin/bash
# 案例4：批量日志分析（Shell 变量/条件/循环/函数综合练习）
set -e

cat > sample.log <<'EOF'
2026-10-12 10:01:01 ERROR auth 登录失败
2026-10-12 10:02:02 INFO order 创建订单
2026-10-12 10:03:03 ERROR pay 支付超时
2026-10-12 10:04:04 WARN user 用户不存在
2026-10-12 10:05:05 ERROR db 数据库连接失败
EOF

cat > log_analyze.sh <<'EOF'
#!/bin/bash
# 案例4：批量日志分析脚本

if [ $# -ne 1 ]; then
  echo "用法：$0 日志文件"
  exit 1
fi

readonly LOG_FILE="$1"

if [ ! -f "$LOG_FILE" ]; then
  echo "文件不存在：$LOG_FILE"
  exit 1
fi

analyze_log() {
  local file="$1"
  local count=0
  local log_date log_time level module message

  echo "错误日志明细："
  while read log_date log_time level module message
  do
    if [ "$level" = "ERROR" ]; then
      count=$((count + 1))
      echo "时间：$log_date $log_time | 模块：$module | 信息：$message"
    fi
  done < "$file"

  return "$count"
}

analyze_log "$LOG_FILE"
error_count=$?
echo "错误日志条数：$error_count"
echo "脚本名：$0，参数个数：$#，当前PID：$$"
exit 0
EOF

chmod +x log_analyze.sh
./log_analyze.sh sample.log