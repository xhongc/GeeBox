#!/bin/bash

# 一键启动 Chanson (Web + Chrome 禁用 CORS)

echo "🎵 启动 Chanson..."
echo ""

# 启动禁用 CORS 的 Chrome
echo "1️⃣ 启动 Chrome (禁用 CORS)..."
open -na "Google Chrome" --args --disable-web-security --user-data-dir="/tmp/chrome_dev" &

# 等待 Chrome 启动
sleep 3

# 启动应用
echo "2️⃣ 启动应用..."
cd /Users/macbookair/coding/chanson
/Users/macbookair/coding/flutter/flutter/bin/flutter run -d chrome

echo ""
echo "✅ 应用已启动！"
echo ""
echo "💡 提示:"
echo "- 使用演示服务器测试: https://demo.subsonic.org"
echo "- 用户名: guest"
echo "- 密码: guest"
