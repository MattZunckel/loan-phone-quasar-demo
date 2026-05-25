import { createRouter, createWebHistory } from 'vue-router'
import MainLayout from '../layouts/MainLayout.vue'
import ApplicationPage from '../pages/ApplicationPage.vue'

const routes = [
  {
    path: '/',
    component: MainLayout,
    children: [
      { path: '', component: ApplicationPage }
    ]
  }
]

export default createRouter({
  history: createWebHistory(),
  routes
})
