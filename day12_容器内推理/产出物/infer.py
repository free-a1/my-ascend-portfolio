# 容器内推理演示：3x1 输入向量与 3x2 权重矩阵的前向计算
# （原 torch 版 x @ w 的等价纯 Python 实现，避免拉取数 GB 的 pytorch 镜像）
x = [1.0, 2.0, 3.0]
w = [[0.1, 0.4], [0.2, 0.5], [0.3, 0.6]]
y = [round(sum(xi * wi for xi, wi in zip(x, col)), 4) for col in zip(*w)]
print("输入:", x)
print("推理输出:", y)
