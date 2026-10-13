import sys
path = sys.argv[1]
with open(path, "r", encoding="utf-8") as f:
    data = f.read()
print("读取数据集:", path)
print(data, end="")
