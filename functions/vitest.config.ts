import { defineConfig } from "vitest/config";

export default defineConfig({
  // CSS/PostCSS не нужен в Node-функциях — отключаем, иначе vite ищет
  // postcss.config.mjs в корне репо (web-настройка с tailwindcss),
  // которая в `functions/node_modules` отсутствует и валит CI.
  css: false,
  test: {
    environment: "node",
    include: ["src/**/*.spec.ts"],
  },
});

