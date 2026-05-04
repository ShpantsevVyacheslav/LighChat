import { defineConfig } from 'vitest/config';

/**
 * Отдельный vitest-конфиг для интеграционных тестов против Firestore-эмулятора.
 * Запускается через `npm run test:emulator`, который вызывает
 * `firebase emulators:exec --only firestore`, чтобы поднять эмулятор и убрать
 * его за собой.
 *
 * Тесты живут под `test/*.emulator.spec.ts` и держатся в стороне от обычного
 * `npm test`, который не зависит от внешних процессов.
 */
export default defineConfig({
  test: {
    include: ['test/**/*.emulator.spec.ts'],
    exclude: ['node_modules/**', 'lib/**'],
    testTimeout: 30_000,
    hookTimeout: 30_000,
    // Один воркер: эмулятор делится между тестами через testEnv.clearFirestore().
    pool: 'forks',
    poolOptions: { forks: { singleFork: true } },
  },
});
