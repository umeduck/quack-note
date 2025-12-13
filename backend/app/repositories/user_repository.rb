# ユーザー情報を DynamoDB で管理するリポジトリ
class UserRepository
  # DynamoDB クライアントとテーブル名を初期化
  def initialize
    @client = DYNAMODB_CLIENT
    @table_name = DYNAMODB_USERS_TABLE
  end

  # ユーザーを作成
  # @param user_id [String] Cognito User Sub (UUID)
  # @param workspace_id [String, nil] ワークスペースID
  # @param email [String] メールアドレス
  # @param name [String] ユーザー名
  # @param role [String] ロール (master, admin, member, etc.)
  # @param status [String] アカウントステータス (pending, active, suspended, etc.)
  # @param created_at [Time] 作成日時
  # @param updated_at [Time] 更新日時
  # @return [Hash] 作成されたユーザー情報
  def create(user_id:, workspace_id:, email:, name: 'test', role: 'member', status: 'pending', created_at: nil, updated_at: nil)
    now = Time.now.getlocal('+09:00').iso8601

    item = {
      'user_id' => user_id,
      'workspace_id' => '1',
      'email' => email,
      'name' => name,
      'role' => role,
      'status' => status,
      'created_at' => now,
      'updated_at' => now
    }

    Rails.logger.info "item to put: #{item.inspect}"

    @client.put_item(
      table_name: @table_name,
      item: item,
      # ユーザーが既に存在する場合は失敗させる
      condition_expression: 'attribute_not_exists(user_id)'
    )

    Rails.logger.info "User created in DynamoDB: user_id=#{user_id}, email=#{email}, role=#{role}"
    item
  rescue Aws::DynamoDB::Errors::ConditionalCheckFailedException => e
    Rails.logger.error "User already exists in DynamoDB: user_id=#{user_id}"
    raise DuplicateUserError, "ユーザーは既に存在します"
  rescue Aws::DynamoDB::Errors::ServiceError => e
    Rails.logger.error "DynamoDB put_item error: #{e.message}"
    raise
  end

  # ユーザーIDでユーザーを取得
  # @param user_id [String] ユーザーID (Cognito sub)
  # @return [Hash, nil] ユーザー情報またはnil
  def find_by_user_id(user_id)
    response = @client.get_item(
      table_name: @table_name,
      key: {
        'user_id' => user_id
      }
    )

    item = response.item
    return nil if item.nil?

    normalize_item(item)
  rescue Aws::DynamoDB::Errors::ServiceError => e
    Rails.logger.error "DynamoDB get_item error: #{e.message}"
    raise
  end

  # メールアドレスでユーザーを検索（GSI使用を想定）
  # 注: これを使用する場合は、DynamoDBにGSI (email-index) を作成する必要があります
  # @param email [String] メールアドレス
  # @return [Hash, nil] ユーザー情報またはnil
  def find_by_email(email)
    response = @client.query(
      table_name: @table_name,
      index_name: 'email-index', # GSI名（DynamoDBで作成が必要）
      key_condition_expression: 'email = :email',
      expression_attribute_values: {
        ':email' => email
      },
      limit: 1
    )

    items = response.items
    return nil if items.empty?

    normalize_item(items.first)
  rescue Aws::DynamoDB::Errors::ServiceError => e
    Rails.logger.error "DynamoDB query error: #{e.message}"
    # GSIが存在しない場合は nil を返す
    nil
  end

  # ユーザーステータスを更新
  # @param user_id [String] ユーザーID (Cognito sub)
  # @param status [String] 新しいステータス
  # @return [Hash] 更新されたユーザー情報
  def update_status(user_id:, status:)
    now = Time.current.zone

    response = @client.update_item(
      table_name: @table_name,
      key: {
        'user_id' => user_id
      },
      update_expression: 'SET #status = :status, updated_at = :updated_at',
      expression_attribute_names: {
        '#status' => 'status'
      },
      expression_attribute_values: {
        ':status' => status,
        ':updated_at' => now
      },
      return_values: 'ALL_NEW'
    )

    Rails.logger.info "User status updated: user_id=#{user_id}, status=#{status}"
    normalize_item(response.attributes)
  rescue Aws::DynamoDB::Errors::ServiceError => e
    Rails.logger.error "DynamoDB update_item error: #{e.message}"
    raise
  end

  # ユーザー情報を更新
  # @param user_id [String] ユーザーID (Cognito sub)
  # @param attributes [Hash] 更新する属性
  # @return [Hash] 更新されたユーザー情報
  def update(user_id:, attributes:)
    now = Time.current.zone

    # 更新可能な属性のみを抽出
    allowed_attributes = %w[workspace_id email name role status]
    update_parts = []
    attribute_values = { ':updated_at' => now }
    attribute_names = {}

    attributes.each do |key, value|
      next unless allowed_attributes.include?(key.to_s)
      next if value.nil?

      attr_key = key.to_s
      placeholder_name = "##{attr_key}"
      placeholder_value = ":#{attr_key}"

      update_parts << "#{placeholder_name} = #{placeholder_value}"
      attribute_names[placeholder_name] = attr_key
      attribute_values[placeholder_value] = value
    end

    return find_by_user_id(user_id) if update_parts.empty?

    update_parts << "updated_at = :updated_at"
    update_expression = "SET #{update_parts.join(', ')}"

    response = @client.update_item(
      table_name: @table_name,
      key: {
        'user_id' => user_id
      },
      update_expression: update_expression,
      expression_attribute_names: attribute_names.empty? ? nil : attribute_names,
      expression_attribute_values: attribute_values,
      return_values: 'ALL_NEW'
    )

    Rails.logger.info "User updated: user_id=#{user_id}"
    normalize_item(response.attributes)
  rescue Aws::DynamoDB::Errors::ServiceError => e
    Rails.logger.error "DynamoDB update_item error: #{e.message}"
    raise
  end

  # ユーザーを削除
  # @param user_id [String] ユーザーID (Cognito sub)
  def delete(user_id)
    @client.delete_item(
      table_name: @table_name,
      key: {
        'user_id' => user_id
      }
    )

    Rails.logger.info "User deleted from DynamoDB: user_id=#{user_id}"
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
      'email' => item['email'],
      'status' => item['status'],
      'created_at' => item['created_at'],
      'updated_at' => item['updated_at'],
      # 設定情報（既存のUserSettingsと共存）
      'meeting_title' => item['meeting_title'],
      'auto_delete_days' => item['auto_delete_days'],
      'slack_webhook_url' => item['slack_webhook_url']
    }
  end
end

# カスタム例外
class DuplicateUserError < StandardError; end
