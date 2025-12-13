import {
  CognitoUserPool,
  CognitoUser,
  AuthenticationDetails
} from 'amazon-cognito-identity-js'
import ApiService from './ApiService'

// Cognito User Pool の設定（SignIn用に残す）
const poolData = {
  UserPoolId: import.meta.env.VITE_COGNITO_USER_POOL_ID,
  ClientId: import.meta.env.VITE_COGNITO_CLIENT_ID
}

const userPool = new CognitoUserPool(poolData)

/**
 * CognitoService
 * AWS Cognito User Pools を使用した認証サービス
 * SignUp/ConfirmSignUp/ResendCodeはバックエンドAPI経由で実行
 */
class CognitoService {
  /**
   * ユーザー登録（バックエンドAPI経由）
   * @param {string} email - メールアドレス
   * @param {string} password - パスワード
   * @returns {Promise<{success: boolean, user_sub?: string, error?: string}>}
   */
  async signUp(email, password) {
    try {
      const result = await ApiService.signUp(email, password)

      return {
        success: true,
        user_sub: result.user_sub,
        userConfirmed: result.user_confirmed,
        codeDeliveryDetails: result.code_delivery_details
      }
    } catch (error) {
      console.error('Sign up error:', error)
      return {
        success: false,
        error: error.error_message || 'サインアップに失敗しました',
        errorCode: error.error_code
      }
    }
  }

  /**
   * 確認コードの検証（バックエンドAPI経由）
   * @param {string} username - ユーザー名（メールアドレス）
   * @param {string} code - 確認コード
   * @returns {Promise<{success: boolean, error?: string}>}
   */
  async confirmSignUp(username, code) {
    try {
      const result = await ApiService.confirmSignUp(username, code)

      return {
        success: true,
        message: result.message
      }
    } catch (error) {
      console.error('Confirmation error:', error)
      return {
        success: false,
        error: error.error_message || '確認コードの検証に失敗しました',
        errorCode: error.error_code
      }
    }
  }

  /**
   * 確認コードの再送信（バックエンドAPI経由）
   * @param {string} username - ユーザー名（メールアドレス）
   * @returns {Promise<{success: boolean, error?: string}>}
   */
  async resendConfirmationCode(username) {
    try {
      const result = await ApiService.resendConfirmationCode(username)

      return {
        success: true,
        message: result.message,
        codeDeliveryDetails: result.code_delivery_details
      }
    } catch (error) {
      console.error('Resend code error:', error)
      return {
        success: false,
        error: error.error_message || '確認コードの再送信に失敗しました',
        errorCode: error.error_code
      }
    }
  }

  /**
   * サインイン
   * @param {string} username - ユーザー名
   * @param {string} password - パスワード
   * @returns {Promise<{success: boolean, session?: object, error?: string}>}
   */
  signIn(username, password) {
    return new Promise((resolve, reject) => {
      const authenticationData = {
        Username: username,
        Password: password
      }

      const authenticationDetails = new AuthenticationDetails(authenticationData)

      const cognitoUser = new CognitoUser({
        Username: username,
        Pool: userPool
      })

      cognitoUser.authenticateUser(authenticationDetails, {
        onSuccess: (session) => {
          resolve({
            success: true,
            session: session,
            idToken: session.getIdToken().getJwtToken(),
            accessToken: session.getAccessToken().getJwtToken(),
            refreshToken: session.getRefreshToken().getToken()
          })
        },
        onFailure: (err) => {
          console.error('Sign in error:', err)
          reject({
            success: false,
            error: err.message || JSON.stringify(err)
          })
        }
      })
    })
  }

  /**
   * サインアウト
   */
  signOut() {
    const cognitoUser = userPool.getCurrentUser()
    if (cognitoUser) {
      cognitoUser.signOut()
    }
  }

  /**
   * 現在のユーザーを取得
   * @returns {CognitoUser|null}
   */
  getCurrentUser() {
    return userPool.getCurrentUser()
  }
}

export default new CognitoService()
