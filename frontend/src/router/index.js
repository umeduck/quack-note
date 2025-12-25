import { createRouter, createWebHistory } from 'vue-router'
import { useAuthStore } from '../stores/auth'
import HomeView from '../views/HomeView.vue'
import RecordView from '../views/RecordView.vue'
import LoginView from '../views/LoginView.vue'
import SignUpView from '../views/SignUpView.vue'
import AuthCallback from '../views/AuthCallback.vue'

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    {
      path: '/login',
      name: 'login',
      component: LoginView,
      meta: { requiresGuest: true }
    },
    {
      path: '/signup',
      name: 'signup',
      component: SignUpView,
      meta: { requiresGuest: true }
    },
    {
      path: '/auth/callback',
      name: 'auth-callback',
      component: AuthCallback,
      meta: { public: true }
    },
    {
      path: '/',
      name: 'home',
      component: HomeView,
      meta: { requiresAuth: true }
    },
    {
      path: '/record',
      name: 'record',
      component: RecordView,
      meta: { requiresAuth: true }
    }
  ]
})

// 認証ガード
router.beforeEach((to, from, next) => {
  const authStore = useAuthStore()
  const isLoggedIn = authStore.isLoggedIn()

  // 公開ページ（認証不要）
  if (to.meta.public) {
    next()
  }
  // 認証が必要なページ
  else if (to.meta.requiresAuth && !isLoggedIn) {
    next({ name: 'login', query: { redirect: to.fullPath } })
  }
  // ゲスト専用ページ（既にログイン済みの場合）
  else if (to.meta.requiresGuest && isLoggedIn) {
    next({ name: 'home' })
  }
  // それ以外は通常通り
  else {
    next()
  }
})

export default router
