module Api
  class AuthController < ::ApplicationController
    # 認証不要のコントローラーなので JwtAuthenticatable を include しない
    before_action :set_cognito_service

    # POST /api/auth/signup
    # ユーザー登録
    # @param email [String] メールアドレス
    # @param password [String] パスワード
    def signup
      name = params[:name]
      email = params[:email]
      password = params[:password]

      if name.blank? || email.blank? || password.blank?
        render json: {
          success: false,
          error_code: 'MissingParameters',
          error_message: '名前とメールアドレスとパスワードは必須です'
        }, status: :bad_request
        return
      end

      result = @cognito_service.sign_up(
        name: name,
        email: email,
        password: password
      )

      if result[:success]
        render json: {
          success: true,
          user_sub: result[:user_sub],
          user_confirmed: result[:user_confirmed],
          code_delivery_details: result[:code_delivery_details]
        }, status: :created
      else
        # エラーコードに応じてHTTPステータスを変更
        status_code = case result[:error_code]
                      when 'UsernameExistsException'
                        :conflict
                      when 'InvalidPasswordException', 'InvalidParameterException'
                        :unprocessable_entity
                      else
                        :internal_server_error
                      end

        render json: {
          success: false,
          error_code: result[:error_code],
          error_message: result[:error_message]
        }, status: status_code
      end
    rescue => e
      Rails.logger.error "Unexpected error in signup: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      render json: {
        success: false,
        error_code: 'InternalError',
        error_message: 'サーバーエラーが発生しました'
      }, status: :internal_server_error
    end

    # POST /api/auth/confirm_signup
    # 確認コードの検証
    # @param username [String] ユーザー名（メールアドレス）
    # @param confirmation_code [String] 確認コード
    def confirm_signup
      username = params[:username]
      confirmation_code = params[:confirmation_code]

      if confirmation_code.blank? || confirmation_code.blank?
        render json: {
          success: false,
          error_code: 'MissingParameters',
          error_message: 'ユーザー名と確認コードは必須です'
        }, status: :bad_request
        return
      end

      result = @cognito_service.confirm_sign_up(
        username: username,
        confirmation_code: confirmation_code
      )

      if result[:success]
        render json: {
          success: true,
          message: result[:message]
        }, status: :ok
      else
        status_code = case result[:error_code]
                      when 'CodeMismatchException', 'ExpiredCodeException'
                        :unprocessable_entity
                      when 'NotAuthorizedException'
                        :forbidden
                      else
                        :internal_server_error
                      end

        render json: {
          success: false,
          error_code: result[:error_code],
          error_message: result[:error_message]
        }, status: status_code
      end
    rescue => e
      Rails.logger.error "Unexpected error in confirm_signup: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      render json: {
        success: false,
        error_code: 'InternalError',
        error_message: 'サーバーエラーが発生しました'
      }, status: :internal_server_error
    end

    # POST /api/auth/resend_confirmation_code
    # 確認コードの再送信
    # @param username [String] ユーザー名（メールアドレス）
    def resend_confirmation_code
      username = params[:username]

      if username.blank?
        render json: {
          success: false,
          error_code: 'MissingParameters',
          error_message: 'ユーザー名は必須です'
        }, status: :bad_request
        return
      end

      result = @cognito_service.resend_confirmation_code(
        username: username
      )

      if result[:success]
        render json: {
          success: true,
          message: result[:message],
          code_delivery_details: result[:code_delivery_details]
        }, status: :ok
      else
        status_code = case result[:error_code]
                      when 'LimitExceededException'
                        :too_many_requests
                      when 'UserNotFoundException'
                        :not_found
                      else
                        :internal_server_error
                      end

        render json: {
          success: false,
          error_code: result[:error_code],
          error_message: result[:error_message]
        }, status: status_code
      end
    rescue => e
      Rails.logger.error "Unexpected error in resend_confirmation_code: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      render json: {
        success: false,
        error_code: 'InternalError',
        error_message: 'サーバーエラーが発生しました'
      }, status: :internal_server_error
    end

    private

    def set_cognito_service
      @cognito_service = CognitoService.new
    end
  end
end
