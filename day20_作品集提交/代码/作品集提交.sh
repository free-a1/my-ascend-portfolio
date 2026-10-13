#!/bin/bash
# 案例20：提交作品集——核验 20 天产出结构 -> 生成提交清单 -> Git 仓库打包(bundle) -> 压缩包
# 说明：为避免污染作品集主目录（不在其内创建 .git），Git 演示在 ~/ascend/day20/submit 副本中进行。
set -e
REPO="/mnt/e/my-ascend-portfolio-main"
WORK="$HOME/ascend/day20"
SUB="$WORK/submit"
mkdir -p "$WORK" && cd "$WORK"

echo "===== 1) 案例天产出结构核验（day01-19：代码 / 截图 / 产出物 / 文档）====="
cd "$REPO"
total_code=0; total_shot=0; total_art=0; ok=0; okdoc=0
for d in $(ls -d day*/ | sort); do
  case "$d" in day20*) continue ;; esac   # day20 为本日提交动作，不计入案例天核验
  n_code=$(ls "$d代码" 2>/dev/null | wc -l)
  n_shot=$(ls "$d截图"/*.png 2>/dev/null | wc -l)
  n_art=$(ls "$d产出物" 2>/dev/null | wc -l)
  n_doc=$(ls "$d"[0-9]*_已填写.doc 2>/dev/null | wc -l)
  printf "%-22s 代码%-2s 截图%-2s 产出物%-2s 文档%-2s\n" "${d%/}" "$n_code" "$n_shot" "$n_art" "$n_doc"
  total_code=$((total_code+n_code)); total_shot=$((total_shot+n_shot)); total_art=$((total_art+n_art))
  [ "$n_code" -gt 0 ] && [ "$n_shot" -gt 0 ] && [ "$n_art" -gt 0 ] && ok=$((ok+1))
  [ "$n_doc" -gt 0 ] && okdoc=$((okdoc+1))
done

echo "===== 2) 汇总统计 ====="
echo "案例天(day01-19) 三件套齐全: $ok / 19    已填写文档齐备: $okdoc / 19    本日(day20)提交动作: 完成"
echo "主脚本合计: $total_code 个    截图合计: $total_shot 张    产出物条目合计: $total_art"

echo "===== 3) 生成提交清单 提交清单.md ====="
cat > "$WORK/提交清单.md" <<EOF
# 昇腾精英班 20 天自学作品集 · 提交清单

- 提交日期：$(date '+%Y-%m-%d')
- 提交仓库：https://github.com/free-a1
- 案例天齐备：$ok / 19（day01-19 代码 / 截图 / 产出物 三件套齐全）
- 已填写文档齐备：$okdoc / 19（每日 9.XX_已填写.doc，另含 day20 共 20 份）
- 主脚本合计：$total_code 个　截图：$total_shot 张　产出物：$total_art 项

## 提交内容
1. 每日 \`dayXX_主题/\`：原始文档(9.XX.doc) + 已填写文档(9.XX_已填写.doc) + 代码/ + 截图/ + 产出物/
2. 仓库说明：README.md
3. 打包产物：作品集_20天.tar.gz、作品集.bundle（Git 仓库打包）

## 环境
- WSL Ubuntu 26.04 (resolute) / Python 3.14 / Docker 29.1.3 / systemd
- 运行方式：每天 \`代码/\` 下主脚本在真实终端执行，输出与截屏留证于同目录
EOF
cat "$WORK/提交清单.md" | head -14

echo "===== 4) Git 仓库打包（在副本中进行，不动主目录）====="
rm -rf "$SUB" && mkdir -p "$SUB"
cp "$REPO/README.md" "$SUB/" 2>/dev/null || true
cp -r "$REPO"/day*/ "$SUB/"
# 剔除上一次的打包产物，避免压缩包把自身旧版本也打进去（体积翻倍且无意义）
find "$SUB" -name '作品集.bundle' -delete
find "$SUB" -name '作品集_20天.tar.gz' -delete
cd "$SUB"
git init -q .
git add -A
git -c user.name="ascend-portfolio" -c user.email="portfolio@local" commit -q -m "作品集：20 天自学案例（代码/截图/产出物/文档）"
git -c user.name="ascend-portfolio" -c user.email="portfolio@local" bundle create "$WORK/作品集.bundle" --all
echo "Git 仓库: $(git log --oneline -1)"
echo "文件数: $(git ls-files | wc -l)"
ls -lh "$WORK/作品集.bundle" | awk '{print "bundle 大小:", $5}'

echo "===== 5) 生成压缩包 作品集_20天.tar.gz ====="
tar -czf "$WORK/作品集_20天.tar.gz" -C "$SUB" .
ls -lh "$WORK/作品集_20天.tar.gz" | awk '{print "压缩包大小:", $5}'

echo "===== 6) 提交产物清单 ====="
ls -lh "$WORK"/提交清单.md "$WORK"/作品集.bundle "$WORK"/作品集_20天.tar.gz | awk '{print $NF, $5}'
echo "===== 作品集提交完成 ====="