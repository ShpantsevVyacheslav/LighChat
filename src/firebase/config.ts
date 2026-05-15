/**
 * `measurementId` (формат `G-XXXXXXX`) пробрасывается через
 * `NEXT_PUBLIC_FIREBASE_MEASUREMENT_ID` env-переменную. Без неё
 * Firebase Analytics SDK инициализируется, но события не доходят до
 * GA4 property — наш server-sink (`/api/analytics/event`) пишет в
 * Firestore-коллекцию `analyticsEvents` всё равно, GA4-дашборд получает
 * данные только при наличии measurementId.
 *
 * Где взять: Firebase Console → Project settings → General → ваше
 * Web-приложение → секция «Your apps» → Measurement ID.
 *
 * После добавления переменной (в `apphosting.yaml` или `.env`)
 * требуется ребилд App Hosting — `NEXT_PUBLIC_*` инлайнятся в бандл
 * на этапе сборки.
 */
const measurementId = process.env.NEXT_PUBLIC_FIREBASE_MEASUREMENT_ID;

export const firebaseConfig = {
  "apiKey": "AIzaSyD9GMaIREDiU4twHnMQg5utITpJ7ZVnlYE",
  "authDomain": "project-72b24.firebaseapp.com",
  "projectId": "project-72b24",
  "storageBucket": "project-72b24.firebasestorage.app",
  "messagingSenderId": "262148817877",
  "appId": "1:262148817877:web:d4191fc34eca6977f0335c",
  ...(measurementId ? { measurementId } : {}),
};
