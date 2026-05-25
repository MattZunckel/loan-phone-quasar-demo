import { configure } from 'quasar/wrappers'

export default configure(function () {
  return {
    boot: ['supabase'],
    css: ['app.scss'],
    extras: ['roboto-font', 'material-icons'],
    build: {
      vueRouterMode: 'history',
      env: {
        VITE_SUPABASE_URL: process.env.VITE_SUPABASE_URL,
        VITE_SUPABASE_ANON_KEY: process.env.VITE_SUPABASE_ANON_KEY
      }
    },
    devServer: {
      open: true
    },
    framework: {
      config: {
        brand: {
          primary: '#facc15',
          secondary: '#0f172a',
          positive: '#16a34a',
          negative: '#dc2626',
          warning: '#f59e0b'
        }
      },
      plugins: ['Notify', 'Loading']
    }
  }
})
