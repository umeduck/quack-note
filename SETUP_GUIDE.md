# QuackNote セットアップガイド

このガイドでは、QuackNote の開発環境を完全にゼロから構築する手順を説明します。

## 📋 前提条件

以下がインストールされていることを確認してください:

- **Docker Desktop**: https://www.docker.com/products/docker-desktop
- **Git**: https://git-scm.com/downloads

## 🚀 完全セットアップ手順

### ステップ 1: プロジェクトの準備

このリポジトリには既に以下のファイルが含まれています:

```
quack-note/
├── docker-compose.yml          ✅ 作成済み
├── .gitignore                  ✅ 作成済み
├── README.md                   ✅ 作成済み
├── SETUP_GUIDE.md             ✅ 作成済み
├── backend/
│   ├── Dockerfile             ✅ 作成済み
│   ├── entrypoint.sh          ✅ 作成済み
│   ├── Gemfile                ✅ 作成済み
│   ├── Gemfile.lock           ✅ 作成済み
│   └── config/
│       └── database.yml       ✅ 作成済み
└── frontend/
    ├── Dockerfile             ✅ 作成済み
    ├── package.json           ✅ 作成済み
    ├── vite.config.js         ✅ 作成済み
    ├── index.html             ✅ 作成済み
    └── src/
        ├── main.js            ✅ 作成済み
        └── App.vue            ✅ 作成済み
```

### ステップ 2: Rails アプリケーションの初期化

バックエンドディレクトリに移動して Rails プロジェクトを初期化します。

```bash
cd backend
```

**Windows (PowerShell または CMD) の場合:**
```powershell
docker run --rm -v ${PWD}:/app -w /app ruby:3.3.9 gem install rails -v 7.1.5
docker run --rm -v ${PWD}:/app -w /app ruby:3.3.9 rails new . --api --database=mysql --skip-git
```

**macOS/Linux の場合:**
```bash
docker run --rm -v $(pwd):/app -w /app ruby:3.3.9 gem install rails -v 7.1.5
docker run --rm -v $(pwd):/app -w /app ruby:3.3.9 rails new . --api --database=mysql --skip-git
```

**重要**: ファイルの上書き確認が表示されたら、以下のように対応してください:

```
Overwrite /app/Gemfile? (enter "h" for help) [Ynaqdhm]
→ n を入力（既存の Gemfile を保持）

Overwrite /app/config/database.yml? (enter "h" for help) [Ynaqdhm]
→ n を入力（既存の database.yml を保持）

その他のファイル (config/application.rb など)
→ Y を入力（上書きして OK）
```

### ステップ 3: CORS 設定の追加

`backend/config/initializers/cors.rb` を作成し、以下を記述します:

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

### ステップ 4: entrypoint.sh に実行権限を付与

**Windows の場合:**
Docker コンテナ内で自動的に実行権限が付与されるため、スキップして OK です。

**macOS/Linux の場合:**
```bash
chmod +x backend/entrypoint.sh
```

### ステップ 5: プロジェクトルートに戻る

```bash
cd ..
```

### ステップ 6: Docker コンテナのビルド

```bash
docker compose build
```

このコマンドで以下が実行されます:
- MySQL イメージのダウンロード
- Ruby 3.3.9 イメージのダウンロードとバックエンドコンテナのビルド
- Node.js 20 イメージのダウンロードとフロントエンドコンテナのビルド

**注意**: 初回ビルドは 10〜15 分程度かかる場合があります。

### ステップ 7: Docker コンテナの起動

```bash
docker compose up
```

初回起動時、以下が自動的に実行されます:

1. **MySQL コンテナ**
   - MySQL 8.0 の起動
   - データベースの初期化

2. **Backend コンテナ**
   - MySQL の起動を待機
   - `rails db:create` (データベース作成)
   - `rails db:migrate` (マイグレーション実行)
   - Rails サーバー起動 (ポート 3000)

3. **Frontend コンテナ**
   - npm パッケージのインストール
   - Vite 開発サーバー起動 (ポート 5173)

**起動成功の確認**

以下のようなログが表示されれば成功です:

```
quacknote_db         | [Server] /usr/sbin/mysqld: ready for connections.
quacknote_backend    | => Booting Puma
quacknote_backend    | => Rails 7.1.5 application starting in development
quacknote_backend    | * Listening on http://0.0.0.0:3000
quacknote_frontend   | VITE v5.x.x  ready in xxx ms
quacknote_frontend   | ➜  Local:   http://localhost:5173/
```

### ステップ 8: アプリケーションへのアクセス

ブラウザで以下の URL にアクセスします:

**フロントエンド**
```
http://localhost:5173
```

QuackNote のトップページが表示され、録音ボタンが表示されれば成功です。

**バックエンド API**
```
http://localhost:3000
```

Rails のエラーページが表示されれば、Rails サーバーが正常に起動しています。

## 🛠️ 開発時のコマンド

### コンテナの起動/停止

```bash
# バックグラウンドで起動
docker compose up -d

# フォアグラウンドで起動（ログを表示）
docker compose up

# 停止
docker compose down

# 停止してボリュームも削除（データベースをリセット）
docker compose down -v
```

### ログの確認

```bash
# すべてのコンテナのログを表示
docker compose logs -f

# 特定のコンテナのログのみ表示
docker compose logs -f backend
docker compose logs -f frontend
docker compose logs -f db
```

### Rails コマンドの実行

```bash
# マイグレーション作成
docker compose exec backend rails generate migration CreateUsers

# マイグレーション実行
docker compose exec backend rails db:migrate

# コンソール起動
docker compose exec backend rails console

# ルート確認
docker compose exec backend rails routes

# テスト実行
docker compose exec backend rspec
```

### Gem の追加

1. `backend/Gemfile` を編集
2. コンテナ内で bundle install を実行:

```bash
docker compose exec backend bundle install
docker compose restart backend
```

### npm パッケージの追加

```bash
# パッケージをインストール
docker compose exec frontend npm install <package-name>

# package.json に保存
docker compose exec frontend npm install --save <package-name>
```

### データベースのリセット

```bash
# データベースを削除して再作成
docker compose exec backend rails db:drop db:create db:migrate

# または、コンテナを再起動
docker compose down -v
docker compose up
```

## 🐛 トラブルシューティング

### エラー: "Bind for 0.0.0.0:3000 failed: port is already allocated"

ポート 3000 が既に使用されています。

**解決方法 1**: 使用中のプロセスを終了

```bash
# Windows
netstat -ano | findstr :3000
# PID を確認して
taskkill /PID <PID> /F

# macOS/Linux
lsof -i :3000
kill -9 <PID>
```

**解決方法 2**: docker-compose.yml でポート番号を変更

```yaml
backend:
  ports:
    - "3001:3000"  # ホスト側を 3001 に変更
```

### エラー: "MySQL connection error"

MySQL の起動に時間がかかっている可能性があります。

```bash
# MySQL のログを確認
docker compose logs db

# MySQL が起動しているか確認
docker compose exec db mysql -uroot -ppassword -e "SELECT 1"
```

### フロントエンドが真っ白

```bash
# フロントエンドのログを確認
docker compose logs frontend

# node_modules を削除して再インストール
docker compose exec frontend rm -rf node_modules
docker compose exec frontend npm install
docker compose restart frontend
```

### Rails サーバーが起動しない

```bash
# backend のログを確認
docker compose logs backend

# 手動で確認
docker compose exec backend bash
bundle install
rails db:create
rails db:migrate
rails server -b 0.0.0.0
```

### ファイルの変更が反映されない

Docker のファイル監視がうまく動作していない可能性があります。

```bash
# コンテナを再起動
docker compose restart backend
docker compose restart frontend
```

## 📚 次のステップ

環境構築が完了したら、以下の機能を実装していきます:

### バックエンド

1. **音声アップロード API**
   - `POST /api/recordings` エンドポイント作成
   - Active Storage の設定

2. **Whisper API 連携**
   - OpenAI API の設定
   - 音声ファイルを Whisper に送信

3. **GPT 要約機能**
   - 文字起こしテキストを GPT に送信
   - 要約結果を保存

4. **Slack 通知**
   - Slack Webhook の設定
   - 要約結果を Slack に送信

### フロントエンド

1. **録音機能の完成**
   - MediaRecorder API の実装
   - 録音データの Blob 化

2. **音声アップロード**
   - FormData での音声送信
   - プログレスバー表示

3. **結果表示**
   - 文字起こし結果の表示
   - 要約結果の表示
   - 履歴一覧

## 🎉 完了

これで QuackNote の開発環境構築は完了です。
Claude Code を使って、どんどん機能を実装していきましょう！
