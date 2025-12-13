/**
 * ApiService
 * バックエンドAPIとの通信を担当するサービス
 */

// バックエンドAPIのベースURL
const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || 'http://localhost:3000'

/**
 * APIリクエストを送信する汎用関数
 * @param {string} endpoint - APIエンドポイント
 * @param {object} options - fetch options
 * @returns {Promise<object>} - レスポンスデータ
 */
async function apiRequest(endpoint, options = {}) {
  const url = `${API_BASE_URL}${endpoint}`

  const defaultHeaders = {
    'Content-Type': 'application/json'
  }

  const config = {
    ...options,
    headers: {
      ...defaultHeaders,
      ...options.headers
    }
  }

  try {
    const response = await fetch(url, config)

    // レスポンスボディを取得
    const data = await response.json()

    // エラーレスポンスの処理
    if (!response.ok) {
      throw {
        status: response.status,
        statusText: response.statusText,
        ...data
      }
    }

    return data
  } catch (error) {
    // ネットワークエラーまたはAPIエラーをスロー
    console.error('API request failed:', error)
    throw error
  }
}

class ApiService {
  /**
   * ユーザー登録
   * @param {string} email - メールアドレス
   * @param {string} password - パスワード
   * @returns {Promise<object>}
   */
  static async signUp(email, password) {
    return apiRequest('/api/auth/signup', {
      method: 'POST',
      body: JSON.stringify({
        email,
        password
      })
    })
  }

  /**
   * 確認コードの検証
   * @param {string} username - ユーザー名（メールアドレス）
   * @param {string} confirmationCode - 確認コード
   * @returns {Promise<object>}
   */
  static async confirmSignUp(username, confirmationCode) {
    return apiRequest('/api/auth/confirm_signup', {
      method: 'POST',
      body: JSON.stringify({
        username,
        confirmation_code: confirmationCode
      })
    })
  }

  /**
   * 確認コードの再送信
   * @param {string} username - ユーザー名（メールアドレス）
   * @returns {Promise<object>}
   */
  static async resendConfirmationCode(username) {
    return apiRequest('/api/auth/resend_confirmation_code', {
      method: 'POST',
      body: JSON.stringify({
        username
      })
    })
  }
}

export default ApiService
