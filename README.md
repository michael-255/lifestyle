# Lifestyle

Lifestyle is a project for managing your daily activities, health, and wellness.

This app can also be used as a reference for building a Vue 3 application with Quasar and Supabase.

## TODO

- Port over basic project setup from `web-app-template-v1`

  - Composables directory
  - Basic UI layout
    - App.vue
    - Views
    - Components
    - base.css
  - Break views into directories for each app

- Create a new Supabase project and enter the following into GitHub secrets:

  - `SUPABASE_ACCESS_TOKEN`
  - `SUPABASE_DB_PASSWORD`
  - `SUPABASE_PROJECT_ID`

- New `LocalDatabase` table: `notifications`
  - Need to figure out how to create, sort, and display notifications
  - Update the model, schema, and types as needed

## Project Setup

```sh
npm install
```

### Compile and Hot-Reload for Development

```sh
npm run dev
```

### Type-Check, Compile and Minify for Production

```sh
npm run build
```

### Run Unit Tests with [Vitest](https://vitest.dev/)

```sh
npm run test:unit
```

### Run End-to-End Tests with [Playwright](https://playwright.dev)

```sh
# Install browsers for the first run
npx playwright install

# When testing on CI, must build the project first
npm run build

# Runs the end-to-end tests
npm run test:e2e
# Runs the tests only on Chromium
npm run test:e2e -- --project=chromium
# Runs the tests of a specific file
npm run test:e2e -- tests/example.spec.ts
# Runs the tests in debug mode
npm run test:e2e -- --debug
```

### Lint with [ESLint](https://eslint.org/)

```sh
npm run lint
```

## Project Creation Steps

### Install Dependencies

```sh
# Create a Vue project (creates project directory and initial files for you)
npm create vue@latest
# Navigate into your project directory and install Quasar dependencies
npm install --save quasar @quasar/extras
npm install --save-dev @quasar/vite-plugin sass-embedded@^1.80.2
# Install other dependencies as needed
npm install @supabase/supabase-js
npx supabase init
npm install zod
npm install dexie
```

### Update `~/src/main.ts`

```ts
import { symRoundedClose } from '@quasar/extras/material-symbols-rounded'
import '@quasar/extras/material-symbols-rounded/material-symbols-rounded.css'
import '@quasar/extras/roboto-font/roboto-font.css'
import { createPinia } from 'pinia'
import { Dialog, Loading, Meta, Notify, Quasar } from 'quasar'
import 'quasar/dist/quasar.css'
import quasarIconSet from 'quasar/icon-set/material-symbols-rounded'
import { createApp } from 'vue'
import App from './App.vue'
import './assets/base.css'
import router from './router'

const app = createApp(App)

app.use(createPinia())
app.use(router)
app.use(Quasar, {
  iconSet: quasarIconSet,
  plugins: {
    Meta,
    Dialog,
    Notify,
    Loading,
  },
  config: {
    dark: true,
    brand: {
      primary: '#1976d2',
      secondary: '#607d8b',
      accent: '#673ab7',
      info: '#0d47a1',
      warning: '#ff6f00',
      negative: '#C10015',
      positive: '#4caf50',
      dark: '#1d1d1d',
      'dark-page': '#121212',
    },
    notify: {
      textColor: 'white',
      position: 'top',
      multiLine: false,
      iconSize: '2rem',
      progress: true,
      actions: [
        {
          icon: symRoundedClose,
          round: true,
          color: 'white',
        },
      ],
    },
    loading: {},
  },
})

app.mount('#app')
```

### Update `~/vite.config.ts`:

```ts
import { quasar, transformAssetUrls } from '@quasar/vite-plugin'
import vue from '@vitejs/plugin-vue'
import { fileURLToPath, URL } from 'node:url'
import { defineConfig } from 'vite'
import vueDevTools from 'vite-plugin-vue-devtools'

export default defineConfig({
  plugins: [
    vue({
      template: { transformAssetUrls },
    }),
    vueDevTools(),
    quasar({
      autoImportComponentCase: 'kebab',
    }),
  ],
  resolve: {
    alias: {
      '@': fileURLToPath(new URL('./src', import.meta.url)),
    },
  },
  base: '/<REPO>/',
})
```

### Update GitHub Pages

Configure GitHub Pages to deploy using GitHub Actions.

- Create workflow file in `~/.github/workflows/deploy-github-pages.yml`
- Add `base: '/REPO/'` to `vite.config.ts`
- Push the latest changes to your repository
- In GitHub for this repository, go to `Settings` > `Pages`
- Under `Build and Deployment` > `Source`, select `GitHub Actions`
- Kick off the workflow and confirm the deployment was successful

## Project Updates

- Update `package.json`

  - `name` (slugified)
  - `description`
  - `version`

- Update `constants.ts`

  - `appTitle`
  - `appDescription`

- Update `~/public/*`

  - Use [RealFaviconGenerator](https://realfavicongenerator.net/) to generate favicons and manifest
  - Update `manifest.webmanifest` with `theme_color` to match `App.vue -> useMeta()`
  - Update `manifest.webmanifest` with `background_color` to match `App.vue -> useMeta()`

- Update `~/public/manifest.webmanifest`

```json
{
  "name": "<PROJECT_NAME>",
  "short_name": "<PROJECT_NAME>",
  "start_url": "<SITE>/<REPO>/",
  "theme_color": "#1976d2",
  "background_color": "black",
  "display": "standalone",
  "orientation": "any",
  "icons": [
    {
      "src": "web-app-manifest-192x192.png",
      "sizes": "192x192",
      "type": "image/png",
      "purpose": "any"
    },
    {
      "src": "web-app-manifest-512x512.png",
      "sizes": "512x512",
      "type": "image/png",
      "purpose": "any"
    }
  ]
}
```

### Update `~/index.html`

```html
<!doctype html>
<html lang="en-US">
  <head></head>
  <body>
    <div id="app"></div>
    <script type="module" src="/src/main.ts"></script>
  </body>
</html>
```

### Update `~/eslint.config.ts`

```ts
export default defineConfigWithVueTs(
  // ...
  {
    rules: {
      '@typescript-eslint/no-explicit-any': 'off',
    },
  },
)
```

### Update `GitHub`

- Description
- Website (Use GitHub Pages)
- Add Topic keywords
- Update the `Include in the home page` section

  - Uncheck `Releases`
  - Uncheck `Packages`
  - Keep `Deployments` (for GitHub Pages)

### Supabase

Create a new Supabase project.

Create GitHub secrets for the project with the Supabase settings:

- `SUPABASE_ACCESS_TOKEN`
- `SUPABASE_DB_PASSWORD`
- `SUPABASE_PROJECT_ID`

Create new database migrations and edge functions as needed with these commands:

```sh
npx supabase migrations new {FILE_NAME}
npx supabase functions new {FILE_NAME}
```

## Credits

- Base `Web App Template` created by Michael Joy (michael-255 on GitHub)
- Initial favicons and manifest created by [RealFaviconGenerator](https://realfavicongenerator.net/)
