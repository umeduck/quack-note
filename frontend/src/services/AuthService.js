import axios from 'axios'

class AuthService {
  constructor() {
    this.cognitoDomain = import.meta.env.VITE_COGNITO_DOMAIN
    this.clientId = import.meta.env.VITE_COGNITO_CLIENT_ID
    this.redirectUri = import.meta.env.VITE_COGNITO_REDIRECT_URI
    this.tokenEndpoint = import.meta.env.VITE_COGNITO_TOKEN_ENDPOINT
  }

  /**
   * Cognito Hosted UI のログイン URL を取得
   */
  getLoginUrl() {
    const base = `${this.cognitoDomain}/login`;

    const query =
      "client_id=" + this.clientId +
      "&response_type=code" +
      "&scope=" + encodeURIComponent("email openid phone") +
      "&redirect_uri=" + encodeURIComponent(this.redirectUri);

    return `${base}?${query}`;
  }

  /**
   * 認可コードをトークンに交換
   * @param {string} code - 認可コード
   * @returns {Promise<Object>} トークン情報
   */
  async exchangeCodeForToken(code) {
    try {
      const params = new URLSearchParams({
        grant_type: 'authorization_code',
        client_id: this.clientId,
        code: code,
        redirect_uri: this.redirectUri
      })

      const response = await axios.post(this.tokenEndpoint, params, {
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded'
        }
      })

      return {
        success: true,
        data: response.data
      }
    } catch (error) {
      console.error('トークン交換エラー:', error)
      return {
        success: false,
        error: error.response?.data || error.message
      }
    }
  }
}

// シングルトンインスタンスをエクスポート
export default new AuthService()
