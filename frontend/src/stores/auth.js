import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import axios from 'axios'
import AuthService from '../services/AuthService'

export const useAuthStore = defineStore('auth', () => {
  // State
  const user = ref(null)
  const token = ref(AuthService.getAccessToken() || null)
  const isAuthenticated = computed(() => AuthService.isLoggedIn())

  // Actions
  const login = async (email, password) => {
    try {
      const apiUrl = import.meta.env.VITE_API_BASE_URL || 'http://localhost:3000'
      const response = await axios.post(`${apiUrl}/api/auth/login`, {
        email,
        password
      })

      token.value = response.data.token
      user.value = response.data.user

      // トークンを localStorage に保存
      localStorage.setItem('token', token.value)

      // axios のデフォルトヘッダーにトークンを設定
      axios.defaults.headers.common['Authorization'] = `Bearer ${token.value}`

      return { success: true }
    } catch (error) {
      console.error('ログインエラー:', error)
      return {
        success: false,
        message: error.response?.data?.message || 'ログインに失敗しました'
      }
    }
  }

  const logout = () => {
    user.value = null
    token.value = null

    // AuthService を使ってログアウト
    AuthService.logout()
    AuthService.removeAuthorizationHeader()
  }

  const checkAuth = async () => {
    if (!AuthService.isLoggedIn()) {
      return false
    }

    try {
      const apiUrl = import.meta.env.VITE_API_BASE_URL || 'http://localhost:3000'
      AuthService.setAuthorizationHeader()

      const response = await axios.get(`${apiUrl}/api/auth/me`)
      user.value = response.data.user
      return true
    } catch (error) {
      console.error('認証チェックエラー:', error)
      logout()
      return false
    }
  }

  // ユーザー情報をセット
  const setUser = (userInfo) => {
    user.value = userInfo
  }

  // トークンをセット
  const setToken = (accessToken) => {
    token.value = accessToken
  }

  // 初期化時にトークンがあれば axios にセット
  if (AuthService.isLoggedIn()) {
    AuthService.setAuthorizationHeader()
    // ユーザー情報を取得
    const userInfo = AuthService.getUserInfo()
    if (userInfo) {
      user.value = userInfo
    }
  }

  return {
    user,
    token,
    isAuthenticated,
    login,
    logout,
    checkAuth,
    setUser,
    setToken
  }
})
