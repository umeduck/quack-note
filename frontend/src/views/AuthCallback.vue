<template>
  <v-container>
    <v-row justify="center" align="center" style="min-height: 70vh;">
      <v-col cols="12" sm="8" md="6" lg="4">
        <v-card class="pa-6" elevation="4">
          <v-card-title class="text-h5 text-center mb-4">
            <v-icon icon="mdi-duck" size="large" class="mr-2" color="primary"></v-icon>
            QuackNote
          </v-card-title>

          <v-card-text class="text-center">
            <!-- ローディング状態 -->
            <div v-if="loading">
              <v-progress-circular
                indeterminate
                color="primary"
                size="64"
                class="mb-4"
              ></v-progress-circular>
              <p class="text-h6">認証処理中...</p>
              <p class="text-body-2 text-medium-emphasis">
                トークンを取得しています
              </p>
            </div>

            <!-- エラー状態 -->
            <div v-else-if="error">
              <v-icon
                icon="mdi-alert-circle"
                size="64"
                color="error"
                class="mb-4"
              ></v-icon>
              <p class="text-h6 text-error mb-4">認証に失敗しました</p>
              <v-alert
                type="error"
                variant="tonal"
                class="mb-4"
              >
                {{ errorMessage }}
              </v-alert>
              <v-btn
                color="primary"
                prepend-icon="mdi-login"
                @click="backToLogin"
              >
                ログインページへ戻る
              </v-btn>
            </div>

            <!-- 成功状態 -->
            <div v-else-if="success">
              <v-icon
                icon="mdi-check-circle"
                size="64"
                color="success"
                class="mb-4"
              ></v-icon>
              <p class="text-h6 text-success mb-4">認証成功！</p>
              <p class="text-body-2 text-medium-emphasis">
                ホームページへリダイレクトしています...
              </p>
            </div>
          </v-card-text>
        </v-card>
      </v-col>
    </v-row>
  </v-container>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import AuthService from '../services/AuthService'
import { useAuthStore } from '../stores/auth'

const router = useRouter()
const authStore = useAuthStore()

const loading = ref(true)
const error = ref(false)
const success = ref(false)
const errorMessage = ref('')

/**
 * URL から認可コードを取得
 */
const getAuthorizationCode = () => {
  const urlParams = new URLSearchParams(window.location.search)
  return urlParams.get('code')
}

/**
 * URL からエラー情報を取得
 */
const getErrorFromUrl = () => {
  const urlParams = new URLSearchParams(window.location.search)
  const error = urlParams.get('error')
  const errorDescription = urlParams.get('error_description')
  return { error, errorDescription }
}

/**
 * トークン交換処理
 */
const handleCallback = async () => {
  try {
    // URL からエラーをチェック
    const { error: urlError, errorDescription } = getErrorFromUrl()
    if (urlError) {
      throw new Error(errorDescription || urlError)
    }

    // 認可コードを取得
    const code = getAuthorizationCode()
    if (!code) {
      throw new Error('認可コードが見つかりません')
    }

    console.log('認可コード取得:', code)

    // 認可コードをトークンに交換
    const result = await AuthService.exchangeCodeForToken(code)

    if (!result.success) {
      throw new Error(result.error?.error_description || 'トークンの取得に失敗しました')
    }

    console.log('トークン取得成功:', result.data)

    // トークンを保存
    AuthService.saveTokens(result.data)

    // axios のヘッダーにトークンを設定
    AuthService.setAuthorizationHeader()

    // ユーザー情報を取得して Pinia ストアに保存
    const userInfo = AuthService.getUserInfo()
    if (userInfo) {
      authStore.setUser(userInfo)
      authStore.setToken(result.data.access_token)
    }

    loading.value = false
    success.value = true

    // 1秒後にホームページへリダイレクト
    setTimeout(() => {
      router.push('/')
    }, 1000)

  } catch (err) {
    console.error('認証エラー:', err)
    loading.value = false
    error.value = true
    errorMessage.value = err.message || '認証処理中にエラーが発生しました'
  }
}

/**
 * ログインページへ戻る
 */
const backToLogin = () => {
  router.push('/login')
}

// コンポーネントマウント時に実行
onMounted(() => {
  handleCallback()
})
</script>

<style scoped>
/* スタイルはここに記述 */
</style>
