FROM ruby:3.3.9

# 環境変数設定
ENV LANG C.UTF-8
ENV TZ Asia/Tokyo
ENV RAILS_ENV development

# 必要なパッケージをインストール
RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends \
    build-essential \
    git \
    nodejs \
    npm \
    tzdata \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Yarn インストール
RUN npm install -g yarn

# 作業ディレクトリ設定
WORKDIR /app

# Gemfile と Gemfile.lock をコピー
COPY Gemfile Gemfile.lock ./

# Bundle install
RUN bundle install

# アプリケーションコードをコピー
COPY . .

# entrypoint.sh に実行権限を付与
RUN chmod +x /app/entrypoint.sh

# ポート公開
EXPOSE 3000

# エントリーポイント設定
ENTRYPOINT ["/app/entrypoint.sh"]
