<template>
  <v-app>
    <v-app-bar color="primary" prominent v-if="authStore.isAuthenticated">
      <v-app-bar-title class="cursor-pointer" @click="$router.push('/')">
        <v-icon icon="mdi-duck" class="mr-2"></v-icon>
        QuackNote
      </v-app-bar-title>

      <v-spacer></v-spacer>

      <v-btn
        :to="{ name: 'home' }"
        :variant="$route.name === 'home' ? 'flat' : 'text'"
        prepend-icon="mdi-home"
      >
        ホーム
      </v-btn>

      <v-btn
        :to="{ name: 'record' }"
        :variant="$route.name === 'record' ? 'flat' : 'text'"
        prepend-icon="mdi-microphone"
      >
        録音
      </v-btn>

      <v-menu>
        <template v-slot:activator="{ props }">
          <v-btn
            v-bind="props"
            icon="mdi-account-circle"
            variant="text"
          ></v-btn>
        </template>

        <v-list>
          <v-list-item>
            <v-list-item-title v-if="authStore.user">
              {{ authStore.user.email || 'ユーザー' }}
            </v-list-item-title>
            <v-list-item-subtitle>
              ログイン中
            </v-list-item-subtitle>
          </v-list-item>

          <v-divider></v-divider>

          <v-list-item @click="handleLogout">
            <template v-slot:prepend>
              <v-icon icon="mdi-logout"></v-icon>
            </template>
            <v-list-item-title>ログアウト</v-list-item-title>
          </v-list-item>
        </v-list>
      </v-menu>
    </v-app-bar>

    <v-main>
      <router-view />
    </v-main>
  </v-app>
</template>

<script setup>
import { useRouter } from 'vue-router'
import { useAuthStore } from './stores/auth'

const router = useRouter()
const authStore = useAuthStore()

const handleLogout = () => {
  authStore.logout()
  router.push({ name: 'login' })
}
</script>

<style scoped>
.cursor-pointer {
  cursor: pointer;
}
</style>
