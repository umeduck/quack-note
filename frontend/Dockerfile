FROM node:20-alpine

# 作業ディレクトリ設定
WORKDIR /app

# package.json と package-lock.json をコピー
COPY package*.json ./

# npm install
RUN npm install

# アプリケーションコードをコピー
COPY . .

# ポート公開
EXPOSE 5173

# 開発サーバー起動
CMD ["npm", "run", "dev", "--", "--host", "0.0.0.0", "--port", "5173"]
