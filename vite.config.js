
import { defineConfig } from 'vite'

export default defineConfig({
  build: {
    outDir: 'dist',
    assetsDir: 'assets',
    rollupOptions: {
      input: {
        main: 'index.html',
        app: 'app.html',
        platforms: 'platforms.html',
        search: 'search.html',
        splash: 'splash.html',
        page2: 'page2.html'
      }
    }
  },
  server: {
    port: 8080,
    open: true
  }
})
