import { defineConfig } from "vitest/config";

export default defineConfig({
  // CSS/PostCSS не нужен в Node-функциях. Vite по умолчанию ищет
  // `postcss.config.mjs` вверх по дереву и натыкается на web-конфиг
  // (tailwind), которого нет в `functions/node_modules` → CI падает.
  // Явно передаём пустой `plugins` — vite не делает auto-resolve.
  css: {
    postcss: { plugins: [] },
  },
  test: {
    environment: "node",
    include: ["src/**/*.spec.ts"],
  },
});

