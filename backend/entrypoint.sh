#!/bin/bash
set -e

echo "Waiting for MySQL to be ready..."

# MySQL の起動を待つ
until mysqladmin ping -h "$DATABASE_HOST" -u"$DATABASE_USERNAME" -p"$DATABASE_PASSWORD" --silent; do
  echo "MySQL is unavailable - sleeping"
  sleep 2
done

echo "MySQL is up - executing command"

# データベースが存在しない場合は作成
bundle exec rails db:create || true

# マイグレーション実行
bundle exec rails db:migrate

# Rails サーバー起動
echo "Starting Rails server..."
bundle exec rails server -b 0.0.0.0 -p 3000
