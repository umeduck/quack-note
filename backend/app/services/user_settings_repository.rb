class UserSettingsRepository
  # DynamoDB クライアントとテーブル名を初期化
  def initialize
    @client = DYNAMODB_CLIENT
    @table_name = DYNAMODB_USERS_TABLE
  end

  # ユーザー設定を取得
  # @param user_id [String] ユーザーID (Cognito sub)
  # @return [Hash, nil] ユーザー設定またはnil
  def find_by_user_id(user_id)
    response = @client.get_item(
      table_name: @table_name,
      key: {
        'user_id' => user_id
      }
    )

    item = response.item
    return nil if item.nil?

    # DynamoDB の Item を Hash に変換
    normalize_item(item)
  rescue Aws::DynamoDB::Errors::ServiceError => e
    Rails.logger.error "DynamoDB get_item error: #{e.message}"
    raise
  end

  # ユーザー設定を作成または更新
  # @param user_id [String] ユーザーID (Cognito sub)
  # @param attributes [Hash] 設定情報
  # @return [Hash] 保存された設定
  def create_or_update(user_id, attributes)
    now = Time.current.iso8601

    # 既存データを取得して created_at を保持
    existing_item = find_by_user_id(user_id)
    created_at = existing_item&.dig('created_at') || now

    item = {
      'user_id' => user_id,
      'meeting_title' => attributes[:meeting_title],
      'auto_delete_days' => attributes[:auto_delete_days],
      'slack_webhook_url' => attributes[:slack_webhook_url],
      'created_at' => created_at,
      'updated_at' => now
    }

    @client.put_item(
      table_name: @table_name,
      item: item
    )

    item
  rescue Aws::DynamoDB::Errors::ServiceError => e
    Rails.logger.error "DynamoDB put_item error: #{e.message}"
    raise
  end

  # ユーザー設定を削除（オプション）
  # @param user_id [String] ユーザーID (Cognito sub)
  def delete(user_id)
    @client.delete_item(
      table_name: @table_name,
      key: {
        'user_id' => user_id
      }
    )
  rescue Aws::DynamoDB::Errors::ServiceError => e
    Rails.logger.error "DynamoDB delete_item error: #{e.message}"
    raise
  end

  private

  # DynamoDB の Item を通常の Hash に変換
  # @param item [Hash] DynamoDB の Item
  # @return [Hash] 正規化された Hash
  def normalize_item(item)
    return nil if item.nil?

    {
      'user_id' => item['user_id'],
      'meeting_title' => item['meeting_title'],
      'auto_delete_days' => item['auto_delete_days'],
      'slack_webhook_url' => item['slack_webhook_url'],
      'created_at' => item['created_at'],
      'updated_at' => item['updated_at']
    }
  end
end
