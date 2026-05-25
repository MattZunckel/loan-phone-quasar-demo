import { createApp } from 'vue'
import { Quasar, Notify, Loading } from 'quasar'
import '@quasar/extras/material-icons/material-icons.css'
import 'quasar/src/css/index.sass'
import './css/app.scss'

import App from './App.vue'
import router from './router'

const app = createApp(App)

app.use(Quasar, {
  plugins: {
    Notify,
    Loading
  },
  config: {
    brand: {
      primary: '#facc15',
      secondary: '#0f172a',
      positive: '#16a34a',
      negative: '#dc2626',
      warning: '#f59e0b'
    }
  }
})

app.use(router)
app.mount('#q-app')
