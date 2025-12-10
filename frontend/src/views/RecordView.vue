<template>
  <v-container>
    <v-row justify="center">
      <v-col cols="12" md="8">
        <v-card class="pa-6" elevation="2">
          <v-card-title class="text-h4 text-center mb-4">
            <v-icon icon="mdi-microphone" class="mr-2" color="primary"></v-icon>
            録音
          </v-card-title>

          <v-card-text>
            <v-alert
              type="info"
              variant="tonal"
              class="mb-4"
            >
              録音 → Stop → 音声アップロード → Whisperで文字起こし → GPT要約 → Slack通知
            </v-alert>

            <v-row>
              <v-col cols="12" class="text-center">
                <v-btn
                  v-if="!isRecording"
                  color="error"
                  size="x-large"
                  @click="startRecording"
                  prepend-icon="mdi-microphone"
                >
                  録音開始
                </v-btn>
                <v-btn
                  v-else
                  color="grey"
                  size="x-large"
                  @click="stopRecording"
                  prepend-icon="mdi-stop"
                >
                  録音停止
                </v-btn>
              </v-col>
            </v-row>

            <v-row v-if="isRecording" class="mt-4">
              <v-col cols="12" class="text-center">
                <v-chip color="error" class="pulse">
                  <v-icon start icon="mdi-record-circle"></v-icon>
                  録音中... {{ recordingTime }}秒
                </v-chip>
              </v-col>
            </v-row>

            <v-row v-if="statusMessage" class="mt-4">
              <v-col cols="12">
                <v-alert
                  :type="statusType"
                  variant="tonal"
                >
                  {{ statusMessage }}
                </v-alert>
              </v-col>
            </v-row>

            <v-row class="mt-6">
              <v-col cols="12" class="text-center">
                <v-btn
                  variant="text"
                  prepend-icon="mdi-arrow-left"
                  :to="{ name: 'home' }"
                >
                  ホームに戻る
                </v-btn>
              </v-col>
            </v-row>
          </v-card-text>
        </v-card>
      </v-col>
    </v-row>
  </v-container>
</template>

<script setup>
import { ref } from 'vue'

const isRecording = ref(false)
const recordingTime = ref(0)
const statusMessage = ref('')
const statusType = ref('info')
let recordingInterval = null
let mediaRecorder = null
let audioChunks = []

const startRecording = async () => {
  try {
    const stream = await navigator.mediaDevices.getUserMedia({ audio: true })
    mediaRecorder = new MediaRecorder(stream)
    audioChunks = []

    mediaRecorder.ondataavailable = (event) => {
      audioChunks.push(event.data)
    }

    mediaRecorder.onstop = async () => {
      const audioBlob = new Blob(audioChunks, { type: 'audio/wav' })
      // ここで音声データをバックエンドに送信する処理を追加
      console.log('録音完了:', audioBlob)
      statusMessage.value = '録音が完了しました。音声処理機能は実装予定です。'
      statusType.value = 'success'
    }

    mediaRecorder.start()
    isRecording.value = true
    recordingTime.value = 0
    statusMessage.value = ''

    recordingInterval = setInterval(() => {
      recordingTime.value++
    }, 1000)
  } catch (error) {
    console.error('録音エラー:', error)
    statusMessage.value = 'マイクへのアクセスが拒否されました。'
    statusType.value = 'error'
  }
}

const stopRecording = () => {
  if (mediaRecorder && isRecording.value) {
    mediaRecorder.stop()
    mediaRecorder.stream.getTracks().forEach(track => track.stop())
    isRecording.value = false
    clearInterval(recordingInterval)
  }
}
</script>

<style scoped>
.pulse {
  animation: pulse 1.5s infinite;
}

@keyframes pulse {
  0%, 100% {
    opacity: 1;
  }
  50% {
    opacity: 0.6;
  }
}
</style>
