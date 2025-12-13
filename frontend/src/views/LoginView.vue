<template>
  <v-container>
    <v-row justify="center" align="center" style="min-height: 70vh;">
      <v-col cols="12" sm="8" md="6" lg="5">
        <v-card class="pa-8" elevation="8">
          <v-card-title class="text-h3 text-center mb-2">
            <v-icon icon="mdi-duck" size="80" class="d-block mx-auto mb-4" color="primary"></v-icon>
            <div class="text-primary">QuackNote</div>
          </v-card-title>

          <v-card-subtitle class="text-center mb-6 text-h6">
            AI 議事録アプリへようこそ
          </v-card-subtitle>

          <v-card-text>
            <v-alert
              type="info"
              variant="tonal"
              class="mb-6"
            >
              <div class="text-body-2">
                Cognito Hosted UI を使用してログインしてください
              </div>
            </v-alert>

            <v-btn
              color="primary"
              block
              size="x-large"
              class="mb-4"
              prepend-icon="mdi-login"
              @click="handleSignIn"
            >
              Sign In
            </v-btn>

            <v-divider class="my-6"></v-divider>

            <div class="text-center mb-6">
              <p class="text-body-2 text-medium-emphasis mb-2">
                アカウントをお持ちでない方
              </p>
              <v-btn
                color="secondary"
                block
                size="large"
                variant="outlined"
                prepend-icon="mdi-account-plus"
                @click="$router.push('/signup')"
              >
                新規登録はこちら
              </v-btn>
            </div>

            <v-divider class="my-6"></v-divider>

            <div class="text-center">
              <p class="text-body-2 text-medium-emphasis mb-2">
                機能概要
              </p>
              <v-chip
                size="small"
                class="ma-1"
                color="primary"
                variant="outlined"
              >
                録音
              </v-chip>
              <v-chip
                size="small"
                class="ma-1"
                color="success"
                variant="outlined"
              >
                文字起こし
              </v-chip>
              <v-chip
                size="small"
                class="ma-1"
                color="info"
                variant="outlined"
              >
                AI 要約
              </v-chip>
              <v-chip
                size="small"
                class="ma-1"
                color="warning"
                variant="outlined"
              >
                Slack 通知
              </v-chip>
            </div>
          </v-card-text>
        </v-card>
      </v-col>
    </v-row>
  </v-container>
</template>

<script setup>
import AuthService from '../services/AuthService'

/**
 * Sign In ボタンのクリックハンドラ
 * Cognito Hosted UI のログインページへ遷移
 */
const handleSignIn = () => {
  const loginUrl = AuthService.getLoginUrl()
  window.location.href = loginUrl
}
</script>

<style scoped>
/* スタイルはここに記述 */
</style>
