#!/bin/bash
set -e

echo "Starting QuackNote backend..."

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
