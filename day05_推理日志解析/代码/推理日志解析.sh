#!/bin/bash
# 案例5：推理日志解析（grep/sed/awk 三件套练习）
set -e

cat > inference.log <<'EOF'
# 推理日志：日期 时间 模型 precision=值 latency=值ms 状态
2026-09-22 10:00:01 resnet50 precision=0.912 latency=35ms OK
2026-09-22 10:00:02 resnet50 precision=0.923 latency=48ms ok
2026-09-22 10:00:03 resnet50 precision=0.901 latency=52ms OK
2026-09-22 10:00:04 resnet50 precision=0.000 latency=999ms FAIL
2026-09-22 10:00:05 resnet50 precision=0.934 latency=41ms OK
EOF

cat > parse_inference.sh <<'EOF'
#!/bin/bash
# 删除注释行和空行，替换掉 precision=、latency=、ms，过滤 OK/ok 行
sed '/^#/d; /^$/d; s/precision=//g; s/latency=//g; s/ms//g' inference.log | grep -i -E 'ok$' > ok.log

# 提取精度和耗时，生成指标报表（含平均值统计）
awk 'BEGIN { print "精度\t耗时(ms)" }
     { print $4 "\t" $5; ps += $4; ls += $5 }
     END { print "总记录数: " NR;
           printf "平均精度: %.4f\t平均耗时: %.2fms\n", ps/NR, ls/NR }' ok.log > report.txt

# 查看报表
cat report.txt
EOF

bash parse_inference.sh
