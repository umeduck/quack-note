import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import axios from 'axios'

export const useAuthStore = defineStore('auth', () => {
  // State - すべての認証情報をPiniaで管理
  const user = ref(null)
  const idToken = ref(null)
  const accessToken = ref(null)
  const refreshToken = ref(null)
  const expiresAt = ref(null)

  const isAuthenticated = computed(() => {
    if (!user.value) return false
    if (!accessToken.value) return false
    if (expiresAt.value && Date.now() > expiresAt.value) {
      logout()
      return false
    }
    return true
  })

  // Actions
  const logout = () => {
    user.value = null
    idToken.value = null
    accessToken.value = null
    refreshToken.value = null
    expiresAt.value = null
    removeAuthorizationHeader()
  }

  const checkAuth = async () => {
    if (!isLoggedIn()) {
      return false
    }

    try {
      const apiUrl = import.meta.env.VITE_API_BASE_URL || 'http://localhost:3000'
      setAuthorizationHeader()

      const response = await axios.get(`${apiUrl}/api/auth/me`)
      user.value = response.data.user
      return true
    } catch (error) {
      console.error('認証チェックエラー:', error)
      logout()
      return false
    }
  }

  // トークンを保存
  const saveTokens = (tokens) => {
    if (tokens.id_token) {
      idToken.value = tokens.id_token
      // JWTデコードしてユーザー情報を取得
      try {
        const payload = tokens.id_token.split('.')[1]
        const decodedPayload = JSON.parse(atob(payload))
        user.value = decodedPayload
      } catch (error) {
        console.error('JWT デコードエラー:', error)
      }
    }
    if (tokens.access_token) {
      console.log('Saving access_token:', tokens.access_token)
      accessToken.value = tokens.access_token
    }
    if (tokens.refresh_token) {
      refreshToken.value = tokens.refresh_token
    }
    if (tokens.expires_in) {
      expiresAt.value = Date.now() + tokens.expires_in * 1000
    }
  }

  // ログイン状態を確認
  const isLoggedIn = () => {
    if (!accessToken.value) {
      return false
    }

    // トークンの有効期限チェック
    if (expiresAt.value && Date.now() > expiresAt.value) {
      logout()
      return false
    }

    return true
  }

  // axios のデフォルトヘッダーにアクセストークンを設定
  const setAuthorizationHeader = () => {
    if (accessToken.value) {
      axios.defaults.headers.common['Authorization'] = `Bearer ${accessToken.value}`
    }
  }

  // axios のデフォルトヘッダーからアクセストークンを削除
  const removeAuthorizationHeader = () => {
    delete axios.defaults.headers.common['Authorization']
  }

  // リフレッシュトークンを使って新しいアクセストークンを取得
  const refreshAccessToken = async (tokenEndpoint, clientId) => {
    if (!refreshToken.value) {
      return { success: false, error: 'リフレッシュトークンがありません' }
    }

    try {
      const params = new URLSearchParams({
        grant_type: 'refresh_token',
        client_id: clientId,
        refresh_token: refreshToken.value
      })

      const response = await axios.post(tokenEndpoint, params, {
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded'
        }
      })

      saveTokens(response.data)

      return {
        success: true,
        data: response.data
      }
    } catch (error) {
      console.error('トークンリフレッシュエラー:', error)
      logout()
      return {
        success: false,
        error: error.response?.data || error.message
      }
    }
  }

  // 初期化時にトークンがあれば axios にセット
  if (isLoggedIn()) {
    setAuthorizationHeader()
  }

  return {
    // State
    user,
    idToken,
    accessToken,
    refreshToken,
    expiresAt,
    // Getters
    isAuthenticated,
    // Actions
    logout,
    checkAuth,
    saveTokens,
    isLoggedIn,
    setAuthorizationHeader,
    removeAuthorizationHeader,
    refreshAccessToken
  }
}, {
  // pinia-plugin-persistedstate の設定
  persist: true
})
