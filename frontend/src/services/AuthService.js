import axios from 'axios'

class AuthService {
  constructor() {
    this.cognitoDomain = import.meta.env.VITE_COGNITO_DOMAIN
    this.clientId = import.meta.env.VITE_COGNITO_CLIENT_ID
    this.redirectUri = import.meta.env.VITE_COGNITO_REDIRECT_URI
    this.scope = import.meta.env.VITE_COGNITO_SCOPE
    this.responseType = import.meta.env.VITE_COGNITO_RESPONSE_TYPE
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
   * Cognito Hosted UI のサインアップ URL を取得
   */
  getSignupUrl() {
    const base = `${this.cognitoDomain}/signup`;

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

  /**
   * トークンを localStorage に保存
   * @param {Object} tokens - トークン情報
   */
  saveTokens(tokens) {
    if (tokens.id_token) {
      localStorage.setItem('id_token', tokens.id_token)
    }
    if (tokens.access_token) {
      localStorage.setItem('access_token', tokens.access_token)
    }
    if (tokens.refresh_token) {
      localStorage.setItem('refresh_token', tokens.refresh_token)
    }
    if (tokens.expires_in) {
      const expiresAt = Date.now() + tokens.expires_in * 1000
      localStorage.setItem('expires_at', expiresAt.toString())
    }
  }

  /**
   * ID トークンを取得
   * @returns {string|null}
   */
  getIdToken() {
    return localStorage.getItem('id_token')
  }

  /**
   * アクセストークンを取得
   * @returns {string|null}
   */
  getAccessToken() {
    return localStorage.getItem('access_token')
  }

  /**
   * リフレッシュトークンを取得
   * @returns {string|null}
   */
  getRefreshToken() {
    return localStorage.getItem('refresh_token')
  }

  /**
   * ログイン状態を確認
   * @returns {boolean}
   */
  isLoggedIn() {
    const accessToken = this.getAccessToken()
    const expiresAt = localStorage.getItem('expires_at')

    if (!accessToken) {
      return false
    }

    // トークンの有効期限チェック
    if (expiresAt && Date.now() > parseInt(expiresAt)) {
      // トークンが期限切れ
      this.logout()
      return false
    }

    return true
  }

  /**
   * ID トークンから ユーザー情報を取得（JWT デコード）
   * @returns {Object|null}
   */
  getUserInfo() {
    const idToken = this.getIdToken()
    if (!idToken) {
      return null
    }

    try {
      // JWT は base64url エンコードされた3つの部分から構成
      const payload = idToken.split('.')[1]
      const decodedPayload = JSON.parse(atob(payload))
      return decodedPayload
    } catch (error) {
      console.error('JWT デコードエラー:', error)
      return null
    }
  }

  /**
   * ログアウト（トークンを削除）
   */
  logout() {
    localStorage.removeItem('id_token')
    localStorage.removeItem('access_token')
    localStorage.removeItem('refresh_token')
    localStorage.removeItem('expires_at')
  }

  /**
   * リフレッシュトークンを使って新しいアクセストークンを取得
   * @returns {Promise<Object>}
   */
  async refreshAccessToken() {
    const refreshToken = this.getRefreshToken()
    if (!refreshToken) {
      return { success: false, error: 'リフレッシュトークンがありません' }
    }

    try {
      const params = new URLSearchParams({
        grant_type: 'refresh_token',
        client_id: this.clientId,
        refresh_token: refreshToken
      })

      const response = await axios.post(this.tokenEndpoint, params, {
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded'
        }
      })

      this.saveTokens(response.data)

      return {
        success: true,
        data: response.data
      }
    } catch (error) {
      console.error('トークンリフレッシュエラー:', error)
      this.logout()
      return {
        success: false,
        error: error.response?.data || error.message
      }
    }
  }

  /**
   * axios のデフォルトヘッダーにアクセストークンを設定
   */
  setAuthorizationHeader() {
    const accessToken = this.getAccessToken()
    if (accessToken) {
      axios.defaults.headers.common['Authorization'] = `Bearer ${accessToken}`
    }
  }

  /**
   * axios のデフォルトヘッダーからアクセストークンを削除
   */
  removeAuthorizationHeader() {
    delete axios.defaults.headers.common['Authorization']
  }
}

// シングルトンインスタンスをエクスポート
export default new AuthService()
