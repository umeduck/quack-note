<template>
  <v-container>
    <v-row justify="center" align="center" style="min-height: 70vh;">
      <v-col cols="12" sm="8" md="6" lg="5">
        <v-card class="pa-8" elevation="8">
          <!-- ヘッダー -->
          <v-card-title class="text-h4 text-center mb-2">
            <v-icon icon="mdi-duck" size="60" class="d-block mx-auto mb-3" color="primary"></v-icon>
            <div class="text-primary">新規登録</div>
          </v-card-title>

          <v-card-subtitle class="text-center mb-6">
            QuackNote アカウントを作成
          </v-card-subtitle>

          <v-card-text>
            <!-- エラーメッセージ -->
            <v-alert
              v-if="errorMessage"
              type="error"
              variant="tonal"
              class="mb-4"
              closable
              @click:close="errorMessage = ''"
            >
              {{ errorMessage }}
            </v-alert>

            <!-- 成功メッセージ -->
            <v-alert
              v-if="successMessage"
              type="success"
              variant="tonal"
              class="mb-4"
            >
              {{ successMessage }}
            </v-alert>

            <!-- サインアップフォーム -->
            <v-form v-if="!showConfirmation" ref="signupForm" @submit.prevent="handleSignUp">
              <!-- 名前 -->
              <v-text-field
                v-model="name"
                label="名前"
                type="text"
                prepend-inner-icon="mdi-account"
                :rules="nameRules"
                variant="outlined"
                required
                class="mb-2"
              ></v-text-field>

              <!-- メールアドレス -->
              <v-text-field
                v-model="email"
                label="メールアドレス"
                type="email"
                prepend-inner-icon="mdi-email"
                :rules="emailRules"
                variant="outlined"
                required
                class="mb-2"
              ></v-text-field>

              <!-- パスワード -->
              <v-text-field
                v-model="password"
                label="パスワード"
                :type="showPassword ? 'text' : 'password'"
                prepend-inner-icon="mdi-lock"
                :append-inner-icon="showPassword ? 'mdi-eye' : 'mdi-eye-off'"
                @click:append-inner="showPassword = !showPassword"
                :rules="passwordRules"
                variant="outlined"
                required
                class="mb-2"
              ></v-text-field>

              <!-- パスワード確認 -->
              <v-text-field
                v-model="passwordConfirm"
                label="パスワード確認"
                :type="showPasswordConfirm ? 'text' : 'password'"
                prepend-inner-icon="mdi-lock-check"
                :append-inner-icon="showPasswordConfirm ? 'mdi-eye' : 'mdi-eye-off'"
                @click:append-inner="showPasswordConfirm = !showPasswordConfirm"
                :rules="passwordConfirmRules"
                variant="outlined"
                required
                class="mb-4"
              ></v-text-field>

              <!-- サインアップボタン -->
              <v-btn
                type="submit"
                color="primary"
                block
                size="large"
                :loading="loading"
                :disabled="loading"
              >
                登録する
              </v-btn>
            </v-form>

            <!-- 確認コード入力フォーム -->
            <v-form v-if="showConfirmation" ref="confirmForm" @submit.prevent="handleConfirm">
              <v-alert
                type="info"
                variant="tonal"
                class="mb-4"
              >
                登録したメールアドレスに確認コードを送信しました。<br>
                確認コードを入力してください。
              </v-alert>

              <!-- 確認コード -->
              <v-text-field
                v-model="confirmationCode"
                label="確認コード"
                prepend-inner-icon="mdi-numeric"
                :rules="[v => !!v || '確認コードを入力してください']"
                variant="outlined"
                required
                class="mb-4"
              ></v-text-field>

              <!-- 確認ボタン -->
              <v-btn
                type="submit"
                color="primary"
                block
                size="large"
                :loading="loading"
                :disabled="loading"
                class="mb-2"
              >
                確認する
              </v-btn>

              <!-- 確認コード再送信 -->
              <v-btn
                color="secondary"
                variant="outlined"
                block
                size="small"
                :disabled="loading"
                @click="handleResendCode"
              >
                確認コードを再送信
              </v-btn>
            </v-form>

            <v-divider class="my-6"></v-divider>

            <!-- ログインリンク -->
            <div class="text-center">
              <p class="text-body-2 text-medium-emphasis">
                既にアカウントをお持ちですか？
              </p>
              <v-btn
                color="primary"
                variant="text"
                @click="$router.push('/login')"
              >
                ログインはこちら
              </v-btn>
            </div>
          </v-card-text>
        </v-card>
      </v-col>
    </v-row>
  </v-container>
</template>

<script setup>
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import CognitoService from '../services/CognitoService'

const router = useRouter()

// フォームデータ
const name = ref('')
const email = ref('')
const password = ref('')
const passwordConfirm = ref('')
const confirmationCode = ref('')

// UI状態
const showPassword = ref(false)
const showPasswordConfirm = ref(false)
const showConfirmation = ref(false)
const loading = ref(false)
const errorMessage = ref('')
const successMessage = ref('')

// バリデーションルール

const nameRules = [
  v => !!v || '名前を入力してください',
  v => (v && v.length <= 50) || '名前は50文字以内で入力してください'
]

const emailRules = [
  v => !!v || 'メールアドレスを入力してください',
  v => /.+@.+\..+/.test(v) || '有効なメールアドレスを入力してください'
]

const passwordRules = [
  v => !!v || 'パスワードを入力してください',
  v => (v && v.length >= 8) || 'パスワードは8文字以上で入力してください',
  v => /[A-Z]/.test(v) || 'パスワードは大文字を1文字以上含む必要があります',
  v => /[a-z]/.test(v) || 'パスワードは小文字を1文字以上含む必要があります',
  v => /[0-9]/.test(v) || 'パスワードは数字を1文字以上含む必要があります'
]

const passwordConfirmRules = [
  v => !!v || 'パスワード確認を入力してください',
  v => v === password.value || 'パスワードが一致しません'
]

/**
 * サインアップ処理
 */
const handleSignUp = async () => {

  loading.value = true
  errorMessage.value = ''
  successMessage.value = ''
  console.log('Signing up user with email:', email.value)

  try {
    const result = await CognitoService.signUp(
      name.value,
      email.value,
      password.value
    )

    if (result.success) {
      successMessage.value = '登録が完了しました。メールに送信された確認コードを入力してください。'
      showConfirmation.value = true
    }
  } catch (error) {
    console.error('Sign up failed:', error)
    errorMessage.value = error.error || 'サインアップに失敗しました'
  } finally {
    loading.value = false
  }
}

/**
 * 確認コード検証処理
 */
const handleConfirm = async () => {
  console.log('Confirming sign up for user:', email.value)
  loading.value = true
  errorMessage.value = ''
  successMessage.value = ''

  try {
    const result = await CognitoService.confirmSignUp(
      email.value,
      confirmationCode.value
    )
    console.log('Confirmation result:')
    console.log(result)

    if (result.success) {
      successMessage.value = 'アカウントの確認が完了しました。ログインページに移動します...'

      // 2秒後にログインページへ遷移
      setTimeout(() => {
        router.push('/login')
      }, 2000)
    } else {
      errorMessage.value = result.error || '確認コードの検証に失敗しました'
    }
  } catch (error) {
    console.error('Confirmation failed:', error)
    errorMessage.value = error.error || '確認コードの検証に失敗しました'
  } finally {
    loading.value = false
  }
}

/**
 * 確認コード再送信処理
 */
const handleResendCode = async () => {
  loading.value = true
  errorMessage.value = ''
  successMessage.value = ''

  try {
    const result = await CognitoService.resendConfirmationCode(email.value)

    if (result.success) {
      successMessage.value = '確認コードを再送信しました。'
    } else {
      errorMessage.value = result.error || '確認コードの再送信に失敗しました'
    }
  } catch (error) {
    console.error('Resend code failed:', error)
    errorMessage.value = error.error || '確認コードの再送信に失敗しました'
  } finally {
    loading.value = false
  }
}
</script>

<style scoped>
/* スタイルはここに記述 */
</style>
