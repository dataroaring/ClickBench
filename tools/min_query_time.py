import sys
import ast

if len(sys.argv) != 2:
    print("用法: python min_values.py <文件名>")
    sys.exit(1)

filename = sys.argv[1]

try:
    with open(filename, 'r') as file:
        for line in file:
            line = line.strip()
            if not line.startswith('['):
                continue  # 忽略非列表行

            if line.endswith(','):
                line = line[:-1]  # 去除末尾逗号

            try:
                values = ast.literal_eval(line)
                if isinstance(values, list):
                    print(min(values))
                else:
                    print(f"忽略非列表内容: {line}")
            except Exception as e:
                print(f"解析失败: {line} | 错误: {e}")
except FileNotFoundError:
    print(f"文件未找到: {filename}")
