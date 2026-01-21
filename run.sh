#!/bin/bash

# Chanson 快速启动脚本
# 使用 Web 平台 + 禁用 CORS 的 Chrome 快速测试应用

echo "🎵 Chanson 快速启动脚本"
echo "========================"
echo ""

# 检查 Flutter 是否可用
FLUTTER_PATH="/Users/macbookair/coding/flutter/flutter/bin/flutter"

if [ ! -f "$FLUTTER_PATH" ]; then
    echo "❌ 错误: 找不到 Flutter"
    echo "请确认 Flutter 安装路径: $FLUTTER_PATH"
    exit 1
fi

echo "✅ Flutter 已找到"
echo ""

# 选项
echo "请选择运行方式:"
echo ""
echo "1. Web 平台 (Chrome - 禁用 CORS)"
echo "   - 适合快速测试 UI"
echo "   - 可以连接 Subsonic 服务器"
echo ""
echo "2. Web 平台 (Chrome - 标准模式)"
echo "   - 仅用于 UI 开发"
echo "   - 无法连接服务器 (CORS 限制)"
echo ""
echo "3. 退出"
echo ""

read -p "请输入选项 (1-3): " choice

case $choice in
    1)
        echo ""
        echo "🚀 启动 Chrome (禁用 CORS)..."
        open -na "Google Chrome" --args --disable-web-security --user-data-dir="/tmp/chrome_dev" &

        echo "⏳ 等待 Chrome 启动..."
        sleep 3

        echo "🚀 启动 Chanson 应用..."
        cd /Users/macbookair/coding/chanson
        $FLUTTER_PATH run -d chrome
        ;;
    2)
        echo ""
        echo "🚀 启动 Chanson 应用 (标准 Chrome)..."
        cd /Users/macbookair/coding/chanson
        $FLUTTER_PATH run -d chrome
        ;;
    3)
        echo "👋 再见!"
        exit 0
        ;;
    *)
        echo "❌ 无效选项"
        exit 1
        ;;
esac
