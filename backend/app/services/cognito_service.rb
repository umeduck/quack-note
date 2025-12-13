require 'aws-sdk-cognitoidentityprovider'

# Cognito User Pool を操作するサービスクラス
# AWS SDK v3 を使用して SignUp, ConfirmSignUp, ResendConfirmationCode を実行
class CognitoService
  # Cognito クライアントの初期化
  def initialize
    @client = Aws::CognitoIdentityProvider::Client.new(
      region: ENV['AWS_REGION'] || 'ap-northeast-1'
    )
    @user_pool_id = ENV['COGNITO_USER_POOL_ID']
    @client_id = ENV['COGNITO_CLIENT_ID']
  end

  # ユーザー登録
  # @param email [String] メールアドレス（usernameとして使用）
  # @param password [String] パスワード
  # @return [Hash] レスポンス
  def sign_up(email:, password:)
    validate_email!(email)
    validate_password!(password)

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

    {
      success: true,
      user_sub: response.user_sub,
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
    @client.confirm_sign_up({
      client_id: @client_id,
      username: username,
      confirmation_code: confirmation_code
    })

    {
      success: true,
      message: 'アカウントの確認が完了しました'
    }
  rescue Aws::CognitoIdentityProvider::Errors::CodeMismatchException => e
    Rails.logger.error "Code mismatch: #{e.message}"
    {
      success: false,
      error_code: 'CodeMismatchException',
      error_message: '確認コードが正しくありません'
    }
  rescue Aws::CognitoIdentityProvider::Errors::ExpiredCodeException => e
    Rails.logger.error "Code expired: #{e.message}"
    {
      success: false,
      error_code: 'ExpiredCodeException',
      error_message: '確認コードの有効期限が切れています'
    }
  rescue Aws::CognitoIdentityProvider::Errors::NotAuthorizedException => e
    Rails.logger.error "Not authorized: #{e.message}"
    {
      success: false,
      error_code: 'NotAuthorizedException',
      error_message: 'ユーザーは既に確認済みです'
    }
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
