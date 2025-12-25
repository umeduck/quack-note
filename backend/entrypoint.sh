#!/bin/bash
set -e

echo "Starting QuackNote backend..."

# server.pid が存在する場合のみ削除
if [ -f tmp/pids/server.pid ]; then
  rm tmp/pids/server.pid
  echo "Removed stale server.pid"
fi

# Bundle install (volume mount後に実行)
# echo "Installing gems..."
# bundle install

# bin/rails に実行権限を付与
if [ -f /app/bin/rails ]; then
  chmod +x /app/bin/rails
fi

# Rails サーバー起動
echo "Starting Rails server..."
bundle exec rails server -b 0.0.0.0 -p 3000
