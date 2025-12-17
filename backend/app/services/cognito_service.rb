require 'aws-sdk-cognitoidentityprovider'

# Cognito User Pool を操作するサービスクラス
# AWS SDK v3 を使用して SignUp, ConfirmSignUp, ResendConfirmationCode を実行
class CognitoService
  MAX_VERIFICATION_ATTEMPTS = 5
  # Cognito クライアントの初期化
  def initialize(user_repository: nil)
    @client = Aws::CognitoIdentityProvider::Client.new(
      region: ENV['AWS_REGION'] || 'ap-northeast-1'
    )
    @user_pool_id = ENV['COGNITO_USER_POOL_ID']
    @client_id = ENV['COGNITO_CLIENT_ID']
    @user_repository = user_repository || UserRepository.new
  end

  # ユーザー登録
  # @param email [String] メールアドレス（usernameとして使用）
  # @param password [String] パスワード
  # @return [Hash] レスポンス
  def sign_up(name:, email:, password:)
    validate_name!(name)
    validate_email!(email)
    validate_password!(password)

    # Cognito にユーザーを登録
    response = @client.sign_up({
      client_id: @client_id,
      username: email,
      password: password,
      user_attributes: [
        {
          name: 'email',
          value: email
        }
      ]
    })

    user_sub = response.user_sub

    Rails.logger.info "response: #{response.inspect}"
    Rails.logger.info "User signed up in Cognito: user_sub=#{user_sub}, email=#{email}"

    # DynamoDB にユーザー情報を保存
    begin
      @user_repository.create(
        user_id: user_sub,
        workspace_id: nil,
        email: email,
        name: name,
        role: 'member',
        status: 'pending',
        created_at: Time.now.zone,
        updated_at: Time.now.zone
      )
    rescue DuplicateUserError => e
      # ユーザーが既に存在する場合（通常は発生しないはず）
      Rails.logger.warn "User already exists in DynamoDB but not in Cognito: #{user_sub}"
    rescue StandardError => e
      # DynamoDB 保存失敗時のエラーログ
      # Cognito には既に登録されているため、ロールバックはできない
      Rails.logger.error "Failed to save user to DynamoDB: #{e.message}"
      Rails.logger.error "User was created in Cognito: user_sub=#{user_sub}, email=#{email}"
      # エラーは記録するが、SignUpは成功として扱う
    end

    {
      success: true,
      user_sub: user_sub,
      user_confirmed: response.user_confirmed,
      code_delivery_details: response.code_delivery_details&.to_h
    }
  rescue Aws::CognitoIdentityProvider::Errors::UsernameExistsException => e
    Rails.logger.error "User already exists: #{e.message}"
    {
      success: false,
      error_code: 'UsernameExistsException',
      error_message: 'このメールアドレスは既に登録されています'
    }
  rescue Aws::CognitoIdentityProvider::Errors::InvalidPasswordException => e
    Rails.logger.error "Invalid password: #{e.message}"
    {
      success: false,
      error_code: 'InvalidPasswordException',
      error_message: 'パスワードがポリシー要件を満たしていません'
    }
  rescue Aws::CognitoIdentityProvider::Errors::InvalidParameterException => e
    Rails.logger.error "Invalid parameter: #{e.message}"
    {
      success: false,
      error_code: 'InvalidParameterException',
      error_message: '入力パラメータが不正です'
    }
  rescue Aws::CognitoIdentityProvider::Errors::ServiceError => e
    Rails.logger.error "Cognito service error: #{e.message}"
    {
      success: false,
      error_code: 'ServiceError',
      error_message: 'サーバーエラーが発生しました'
    }
  rescue StandardError => e
    Rails.logger.error "Unexpected error in sign_up: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    {
      success: false,
      error_code: 'UnexpectedError',
      error_message: '予期しないエラーが発生しました'
    }
  end

  # 確認コードの検証
  # @param username [String] ユーザー名（メールアドレス）
  # @param confirmation_code [String] 確認コード
  # @return [Hash] レスポンス
  def confirm_sign_up(username:, confirmation_code:)
    user = nil

    begin
      # Cognito で確認コードを検証
      @client.confirm_sign_up({
        client_id: @client_id,
        username: username,
        confirmation_code: confirmation_code
      })

      # 成功: DynamoDB のユーザーステータスを active に更新 & 失敗回数をリセット
      user = get_user_by_username(username)
      if user
        @user_repository.update_status(
          user_id: user['user_sub'],
          status: 'active'
        )
        @user_repository.reset_verification_attempts(user_id: user['user_sub'])
        Rails.logger.info "User status updated to active and verification attempts reset: #{user['user_sub']}"
      else
        Rails.logger.warn "User not found in Cognito after successful confirmation: #{username}"
      end

      {
        success: true,
        message: 'アカウントの確認が完了しました'
      }

    rescue Aws::CognitoIdentityProvider::Errors::CodeMismatchException => e
      Rails.logger.error "Code mismatch for user: #{username} - #{e.message}"

      # 失敗回数をカウント
      user = get_user_by_username(username)
      if user
        begin
          updated_user = @user_repository.increment_verification_attempts(user_id: user['user_sub'])
          attempts = updated_user['verification_attempts'] || 0

          Rails.logger.warn "Verification attempt failed: user_id=#{user['user_sub']}, attempts=#{attempts}/#{MAX_VERIFICATION_ATTEMPTS}"

          # 5回以上失敗したらアカウントをロック
          if attempts >= MAX_VERIFICATION_ATTEMPTS
            @user_repository.update_status(user_id: user['user_sub'], status: 'locked')
            Rails.logger.error "Account locked due to too many verification attempts: user_id=#{user['user_sub']}"

            return {
              success: false,
              error_code: 'TooManyAttempts',
              error_message: '確認コードの入力失敗回数が上限（5回）に達しました。アカウントがロックされました。サポートにお問い合わせください。'
            }
          end
        rescue StandardError => repo_error
          Rails.logger.error "Failed to increment verification attempts: #{repo_error.message}"
        end
      end

      {
        success: false,
        error_code: 'CodeMismatchException',
        error_message: '確認コードが正しくありません'
      }

    rescue Aws::CognitoIdentityProvider::Errors::ExpiredCodeException => e
      Rails.logger.error "Code expired for user: #{username} - #{e.message}"

      # コード期限切れ: ステータスを verification_expired に更新（任意）
      begin
        user = get_user_by_username(username)
        if user
          @user_repository.update_status(
            user_id: user['user_sub'],
            status: 'verification_expired'
          )
          Rails.logger.info "User status updated to verification_expired: #{user['user_sub']}"
        end
      rescue StandardError => update_error
        Rails.logger.error "Failed to update status to verification_expired: #{update_error.message}"
      end

      {
        success: false,
        error_code: 'ExpiredCodeException',
        error_message: '確認コードの有効期限が切れています'
      }

    rescue Aws::CognitoIdentityProvider::Errors::NotAuthorizedException => e
      Rails.logger.error "Not authorized: #{e.message}"

      # 既に確認済み: ステータスを active に更新
      begin
        user = get_user_by_username(username)
        if user
          @user_repository.update_status(
            user_id: user['user_sub'],
            status: 'active'
          )
          Rails.logger.info "User already confirmed, status updated to active: #{user['user_sub']}"
        end
      rescue StandardError => update_error
        Rails.logger.error "Failed to update status for already confirmed user: #{update_error.message}"
      end

      {
        success: false,
        error_code: 'NotAuthorizedException',
        error_message: 'ユーザーは既に確認済みです'
      }
    end
  rescue Aws::CognitoIdentityProvider::Errors::ServiceError => e
    Rails.logger.error "Cognito service error: #{e.message}"
    {
      success: false,
      error_code: 'ServiceError',
      error_message: 'サーバーエラーが発生しました'
    }
  rescue StandardError => e
    Rails.logger.error "Unexpected error in confirm_sign_up: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    {
      success: false,
      error_code: 'UnexpectedError',
      error_message: '予期しないエラーが発生しました'
    }
  end

  # 確認コードの再送信
  # @param username [String] ユーザー名（メールアドレス）
  # @return [Hash] レスポンス
  def resend_confirmation_code(username:)
    response = @client.resend_confirmation_code({
      client_id: @client_id,
      username: username
    })

    {
      success: true,
      message: '確認コードを再送信しました',
      code_delivery_details: response.code_delivery_details&.to_h
    }
  rescue Aws::CognitoIdentityProvider::Errors::LimitExceededException => e
    Rails.logger.error "Limit exceeded: #{e.message}"
    {
      success: false,
      error_code: 'LimitExceededException',
      error_message: '再送信の試行回数が上限に達しました。しばらく待ってから再度お試しください'
    }
  rescue Aws::CognitoIdentityProvider::Errors::UserNotFoundException => e
    Rails.logger.error "User not found: #{e.message}"
    {
      success: false,
      error_code: 'UserNotFoundException',
      error_message: 'ユーザーが見つかりません'
    }
  rescue Aws::CognitoIdentityProvider::Errors::ServiceError => e
    Rails.logger.error "Cognito service error: #{e.message}"
    {
      success: false,
      error_code: 'ServiceError',
      error_message: 'サーバーエラーが発生しました'
    }
  rescue StandardError => e
    Rails.logger.error "Unexpected error in resend_confirmation_code: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    {
      success: false,
      error_code: 'UnexpectedError',
      error_message: '予期しないエラーが発生しました'
    }
  end

  private

  # ユーザー名（メールアドレス）からユーザー情報を取得
  # @param username [String] ユーザー名（メールアドレス）
  # @return [Hash, nil] ユーザー情報
  def get_user_by_username(username)
    response = @client.admin_get_user({
      user_pool_id: @user_pool_id,
      username: username
    })

    {
      'user_sub' => response.user_attributes.find { |attr| attr.name == 'sub' }&.value,
      'email' => response.user_attributes.find { |attr| attr.name == 'email' }&.value,
      'email_verified' => response.user_attributes.find { |attr| attr.name == 'email_verified' }&.value,
      'status' => response.user_status
    }
  rescue Aws::CognitoIdentityProvider::Errors::UserNotFoundException
    nil
  rescue Aws::CognitoIdentityProvider::Errors::ServiceError => e
    Rails.logger.error "Failed to get user from Cognito: #{e.message}"
    nil
  end

  def validate_name!(name)
    raise ArgumentError, 'Name is required' if name.blank?
    raise ArgumentError, 'Name must be at most 50 characters' if name.length > 50
  end

  # メールアドレスの簡易バリデーション
  def validate_email!(email)
    raise ArgumentError, 'Email is required' if email.blank?
    raise ArgumentError, 'Invalid email format' unless email.match?(/\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i)
  end

  # パスワードの簡易バリデーション
  def validate_password!(password)
    raise ArgumentError, 'Password is required' if password.blank?
    raise ArgumentError, 'Password must be at least 8 characters' if password.length < 8
  end
end
