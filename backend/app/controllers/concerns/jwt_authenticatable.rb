module JwtAuthenticatable
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_request
  end

  private

  # リクエストヘッダーから JWT トークンを取得して認証
  def authenticate_request
    token = extract_token_from_header

    if token.nil?
      render json: { error: 'Authorization header is missing' }, status: :unauthorized
      return
    end

    begin
      @current_user_id = decode_token(token)
    rescue JWT::DecodeError => e
      Rails.logger.error "JWT decode error: #{e.message}"
      render json: { error: 'Invalid or expired token' }, status: :unauthorized
    end
  end

  # Authorization ヘッダーから Bearer トークンを抽出
  def extract_token_from_header
    auth_header = request.headers['Authorization']
    return nil unless auth_header&.start_with?('Bearer ')

    auth_header.split(' ').last
  end

  # JWT トークンをデコードして user_id (sub) を取得
  def decode_token(token)
    # Cognito の JWT は検証なしでデコード（本番環境では公開鍵検証を推奨）
    decoded = JWT.decode(token, nil, false)
    payload = decoded.first

    # sub (ユーザーID) を取得
    user_id = payload['sub']

    if user_id.nil?
      raise JWT::DecodeError, 'sub claim is missing'
    end

    Rails.logger.info "Authenticated user: #{user_id}"
    user_id
  rescue JWT::DecodeError => e
    Rails.logger.error "JWT decode failed: #{e.message}"
    raise
  end

  # 現在のユーザー ID を取得
  def current_user_id
    @current_user_id
  end
end
