#!/bin/bash
# 案例1：搭建学习工作区（Linux 基础）
set -e

echo "===== 1. 创建标准工作区目录树 ====="
mkdir -p ~/project/{code,data,log,doc}

echo "===== 2. 查看目录树 ====="
find ~/project -maxdepth 2

echo "===== 3. 生成命令速查表 ====="
cat > ~/project/doc/linux_quickref.md <<'EOF'
# Linux 命令速查表

| 命令 | 作用 | 示例 |
|---|---|---|
| ls -la | 查看全部文件（含隐藏） | ls -la ~/project |
| cd / pwd | 切换目录 / 显示当前路径 | cd ~/project/doc |
| mkdir -p | 递归创建目录 | mkdir -p a/b/c |
| cp -r | 递归复制目录 | cp -r src dst |
| mv | 移动 / 重命名 | mv old.txt new.txt |
| find -name | 按名称查找文件 | find ~/project -name "*.md" |
| cat | 查看文件内容 | cat linux_quickref.md |
| rm -rf | 递归删除（慎用！） | rm -rf tmpdir |
EOF
echo "速查表已生成：~/project/doc/linux_quickref.md"
echo "===== 工作区搭建完成 ====="
