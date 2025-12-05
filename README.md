# QuackNote - AI議事録アプリ

QuackNote は「録音 → Stop → 音声アップロード → Whisperで文字起こし → GPT要約 → Slack通知」を行う Web アプリです。

## 技術スタック

### フロントエンド
- Vue 3
- Vite
- Vuetify 3
- Axios
- MediaRecorder API

### バックエンド
- Ruby 3.3.9
- Rails 7.1.5 (API mode)
- MySQL 8.x
- Puma

### 開発環境
- Docker
- Docker Compose

## プロジェクト構成

```
quack-note/
├── docker-compose.yml
├── backend/
│   ├── Dockerfile
│   ├── entrypoint.sh
│   ├── Gemfile
│   ├── Gemfile.lock
│   └── config/
│       └── database.yml
├── frontend/
│   ├── Dockerfile
│   ├── package.json
│   ├── vite.config.js
│   ├── index.html
│   └── src/
│       ├── main.js
│       └── App.vue
└── README.md
```

## 環境構築手順

### 前提条件
- Docker Desktop がインストールされていること
- Git がインストールされていること

### 1. Rails アプリケーションの初期化

バックエンドディレクトリで Rails アプリケーションを初期化します。

```bash
cd backend
rails new . --api --database=mysql --skip-git
```

既存のファイルを上書きするか聞かれた場合、以下のように対応してください:
- `Gemfile` → **上書きしない（n）** - 既存の Gemfile を使用
- `config/database.yml` → **上書きしない（n）** - 既存の database.yml を使用
- その他のファイル → 基本的に上書きして問題ありません

### 2. Docker コンテナのビルドと起動

プロジェクトルートディレクトリで以下を実行:

```bash
# Docker イメージをビルド
docker compose build

# コンテナを起動
docker compose up
```

初回起動時は以下の処理が自動実行されます:
- MySQL の起動待機
- データベースの作成 (`rails db:create`)
- マイグレーションの実行 (`rails db:migrate`)
- Rails サーバーの起動

### 3. アクセス確認

コンテナ起動後、以下の URL にアクセスできます:

- **フロントエンド**: http://localhost:5173
- **バックエンド API**: http://localhost:3000
- **MySQL**: localhost:3306

## 開発時の操作

### コンテナの起動/停止

```bash
# バックグラウンドで起動
docker compose up -d

# ログを確認
docker compose logs -f

# 停止
docker compose down

# 停止 + ボリューム削除（データベースもリセット）
docker compose down -v
```

### Rails コマンドの実行

```bash
# コンテナ内でコマンド実行
docker compose exec backend bundle exec rails console
docker compose exec backend bundle exec rails db:migrate
docker compose exec backend bundle exec rails routes

# または bash に入る
docker compose exec backend bash
```

### フロントエンドの npm コマンド実行

```bash
# コンテナ内でコマンド実行
docker compose exec frontend npm install <package-name>

# または bash に入る
docker compose exec frontend sh
```

## CORS 設定

フロントエンドからバックエンド API にアクセスできるよう、Rails 側で CORS を設定する必要があります。

`backend/config/initializers/cors.rb` を作成し、以下を追加:

```ruby
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins 'http://localhost:5173'
    resource '*',
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options, :head]
  end
end
```

## トラブルシューティング

### MySQL 接続エラー

```bash
# MySQL コンテナのログ確認
docker compose logs db

# MySQL に直接接続して確認
docker compose exec db mysql -uroot -ppassword
```

### ポートが既に使用されている

```bash
# 使用中のポートを確認
# Windows
netstat -ano | findstr :3000
netstat -ano | findstr :5173
netstat -ano | findstr :3306

# プロセスを終了するか、docker-compose.yml でポート番号を変更
```

### Rails サーバーが起動しない

```bash
# backend コンテナのログ確認
docker compose logs backend

# コンテナに入って手動で確認
docker compose exec backend bash
bundle install
rails db:create
rails db:migrate
```

## 次のステップ

1. **バックエンド API の実装**
   - 音声ファイルアップロード用のエンドポイント作成
   - Whisper API との連携
   - GPT API との連携
   - Slack 通知機能の実装

2. **フロントエンドの機能追加**
   - 録音機能の完成
   - 音声ファイルのアップロード処理
   - 文字起こし結果の表示
   - 要約結果の表示

3. **認証機能の追加**
   - JWT 認証の実装
   - ユーザー登録/ログイン

## ライセンス

このプロジェクトは開発中です。

## 作成者

QuackNote Development Team
