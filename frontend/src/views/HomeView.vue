<template>
  <v-container>
    <v-row justify="center">
      <v-col cols="12" md="10" lg="8">
        <v-card class="pa-8" elevation="4">
          <v-card-title class="text-h3 text-center mb-6">
            <v-icon icon="mdi-duck" size="x-large" class="mr-3" color="primary"></v-icon>
            QuackNote へようこそ
          </v-card-title>

          <v-card-text>
            <v-row>
              <v-col cols="12" class="text-center mb-4">
                <p class="text-h5 text-medium-emphasis">
                  AI を活用した次世代の議事録アプリ
                </p>
              </v-col>
            </v-row>

            <v-row class="my-6">
              <v-col cols="12" md="6">
                <v-card variant="tonal" color="primary" class="pa-4">
                  <v-card-title class="d-flex align-center">
                    <v-icon icon="mdi-microphone" class="mr-2"></v-icon>
                    簡単録音
                  </v-card-title>
                  <v-card-text>
                    会議やミーティングの音声をワンクリックで録音開始
                  </v-card-text>
                </v-card>
              </v-col>

              <v-col cols="12" md="6">
                <v-card variant="tonal" color="success" class="pa-4">
                  <v-card-title class="d-flex align-center">
                    <v-icon icon="mdi-text-box-outline" class="mr-2"></v-icon>
                    自動文字起こし
                  </v-card-title>
                  <v-card-text>
                    Whisper AI が音声を高精度でテキスト化
                  </v-card-text>
                </v-card>
              </v-col>

              <v-col cols="12" md="6">
                <v-card variant="tonal" color="info" class="pa-4">
                  <v-card-title class="d-flex align-center">
                    <v-icon icon="mdi-note-text" class="mr-2"></v-icon>
                    AI 要約
                  </v-card-title>
                  <v-card-text>
                    GPT が重要なポイントを自動で要約
                  </v-card-text>
                </v-card>
              </v-col>

              <v-col cols="12" md="6">
                <v-card variant="tonal" color="warning" class="pa-4">
                  <v-card-title class="d-flex align-center">
                    <v-icon icon="mdi-slack" class="mr-2"></v-icon>
                    Slack 通知
                  </v-card-title>
                  <v-card-text>
                    結果を自動的に Slack チャンネルへ共有
                  </v-card-text>
                </v-card>
              </v-col>
            </v-row>

            <v-row class="mt-8">
              <v-col cols="12" class="text-center">
                <v-btn
                  color="primary"
                  size="x-large"
                  prepend-icon="mdi-microphone"
                  :to="{ name: 'record' }"
                >
                  録音を始める
                </v-btn>
              </v-col>
            </v-row>

            <v-divider class="my-8"></v-divider>

            <v-row>
              <v-col cols="12">
                <v-alert type="info" variant="tonal">
                  <v-alert-title class="d-flex align-center">
                    <v-icon icon="mdi-information" class="mr-2"></v-icon>
                    使い方
                  </v-alert-title>
                  <ol class="mt-2">
                    <li>「録音を始める」ボタンをクリック</li>
                    <li>会議やミーティングの内容を録音</li>
                    <li>録音停止ボタンで録音を終了</li>
                    <li>AI が自動で文字起こし・要約を実行</li>
                    <li>Slack に結果が自動通知されます</li>
                  </ol>
                </v-alert>
              </v-col>
            </v-row>
          </v-card-text>
        </v-card>
      </v-col>
    </v-row>
  </v-container>
</template>

<script setup>
// ホームページのロジックはここに記述
</script>

<style scoped>
ol {
  padding-left: 20px;
}

ol li {
  margin: 8px 0;
}
</style>
