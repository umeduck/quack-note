require 'aws-sdk-dynamodb'

# DynamoDB クライアントを初期化
DYNAMODB_CLIENT = Aws::DynamoDB::Client.new(
  region: ENV.fetch('AWS_REGION', 'ap-northeast-1'),
  # ローカル開発用の設定（オプション）
  # endpoint: ENV['DYNAMODB_ENDPOINT'], # 例: http://localhost:8000
  # credentials: Aws::Credentials.new('dummy', 'dummy')
)

# DynamoDB テーブル名
DYNAMODB_USERS_TABLE = ENV.fetch('DYNAMODB_USERS_TABLE', 'dev_quacknote_users')

Rails.logger.info "DynamoDB initialized with region: #{ENV.fetch('AWS_REGION', 'ap-northeast-1')}"
Rails.logger.info "DynamoDB users table: #{DYNAMODB_USERS_TABLE}"
