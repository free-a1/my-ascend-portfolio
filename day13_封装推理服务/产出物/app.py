import os

model_name = os.environ.get("MODEL_NAME", "unknown")
x = [1.0, 2.0, 3.0]
w = [[0.1, 0.4], [0.2, 0.5], [0.3, 0.6]]
y = [round(sum(xi * wi for xi, wi in zip(x, col)), 4) for col in zip(*w)]
print("模型名称:", model_name)
print("输入:", x)
print("推理输出:", y)
