# CORS для Firebase Storage (обои чата, `crossOrigin`)

## Пошагово «с нуля» (если непонятно, что вообще делать)

1. **Смысл:** сайт на `https://project-72b24.web.app` уже **скачивает** файл (код 200), но браузер **запрещает** программе читать картинку из Storage, пока на стороне хранилища не сказано: «этому сайту можно». Это как раз CORS — вы один раз выставляете разрешение на **бакет** в Google Cloud.

2. **Установите Google Cloud SDK** на Mac (даёт команды `gcloud` и `gsutil`):  
   https://cloud.google.com/sdk/docs/install  
   После установки откройте **Терминал**.

3. **Перейдите в папку проекта LighChat** на диске (где лежит файл `scripts/firebase-storage-cors.json`):

   ```bash
   cd /Users/macbook1/Desktop/LighChat
   ```

   (Если проект в другом месте — подставьте свой путь.)

4. **Войдите под тем же Google-аккаунтом**, которым пользуетесь в Firebase Console:

   ```bash
   gcloud auth login
   ```

   Откроется браузер — подтвердите вход.

5. **Укажите проект** (у вас в коде `projectId`: `project-72b24`):

   ```bash
   gcloud config set project project-72b24
   ```

6. **Примените CORS** из файла в репозитории к бакету из `storageBucket`:

   ```bash
   gsutil cors set scripts/firebase-storage-cors.json gs://project-72b24.firebasestorage.app
   ```

7. **Проверьте**, что настройка записалась:

   ```bash
   gsutil cors get gs://project-72b24.firebasestorage.app
   ```

   Должны увидеть JSON с `"origin"` и вашими адресами.

8. **Обновите сайт** в Safari (лучше с полным перезагрузом страницы) и снова откройте чат с обоями.

**Если команда ругается на бакет:** в [Firebase Console](https://console.firebase.google.com/) → ваш проект → **Storage** → вверху часто указано имя бакета. Подставьте его вместо `project-72b24.firebasestorage.app` в команде `gsutil … gs://ИМЯ_БАКЕТА`.

**Свой домен** (не `web.app`): для него отдельная строка не в `firebase-storage-cors.json`. Откройте файл, в массив `"origin"` добавьте точный адрес, например `"https://chat.ваш-домен.ru"`, сохраните и **снова** выполните шаг 6.

---

## Почему возникает ошибка

Тот же механизим CORS нужен, когда картинка с Storage рисуется в **canvas** для **виртуального фона в звонке**: в [src/hooks/use-meeting-webrtc.ts](src/hooks/use-meeting-webrtc.ts) для фонов используется `Image` с **`crossOrigin = 'anonymous'`** и `drawImage` после MediaPipe Selfie Segmentation. Без CORS на бакете консоль покажет что-то вроде `Access to image at 'https://firebasestorage.googleapis.com/...' ... blocked by CORS policy`.

В [src/lib/chat-app-theme.ts](src/lib/chat-app-theme.ts) функция `sampleWallpaperImageAverageRgb` тоже создаёт `Image()` с **`crossOrigin = 'anonymous'`**, чтобы нарисовать картинку в `<canvas>` и прочитать пиксели (`getImageData`). Такой запрос — **CORS**, и ответ Storage должен содержать `Access-Control-Allow-Origin` с вашим хостом (или подходящий wildcard-ответ от GCS).

Если CORS на **бакете** не настроен, в Safari/WebKit чаще всего:

- `Origin https://… is not allowed by Access-Control-Allow-Origin. Status code: 200`
- `Cannot load image … firebasestorage.googleapis.com … due to access control checks`

Статус **200** при этом нормален: файл отдаётся, но браузер **не даёт** JS использовать ответ без разрешённого CORS.

Обычный `<img src="…">` **без** `crossOrigin` часто работает и без CORS; у нас `crossOrigin` **нужен** по задумке (цвета темы из фона).

## Что сделать

1. Установите [Google Cloud SDK](https://cloud.google.com/sdk/docs/install) (команда `gsutil`).

2. Войдите и выберите проект Firebase (тот же, что в [src/firebase/config.ts](src/firebase/config.ts)):

   ```bash
   gcloud auth login
   gcloud config set project project-72b24
   ```

3. Примените CORS к **бакету** из `storageBucket` (для этого проекта по умолчанию — `project-72b24.firebasestorage.app`):

   ```bash
   gsutil cors set scripts/firebase-storage-cors.json gs://project-72b24.firebasestorage.app
   ```

4. Проверка:

   ```bash
   gsutil cors get gs://project-72b24.firebasestorage.app
   ```

5. Добавьте в [scripts/firebase-storage-cors.json](scripts/firebase-storage-cors.json) **свой прод-домен** (если используете custom domain на Hosting), затем снова выполните `gsutil cors set …`.

**Правила безопасности** в [storage.rules](storage.rules) не заменяют CORS: CORS настраивается отдельно на уровне **объектного хранилища** (GCS).

## Связь с ошибками Firestore в Safari

Блокировки `firestore.googleapis.com` (другая служба) и Storage различаются. Если после настройки CORS остаются только ошибки Firestore — см. [troubleshooting-safari-firestore.md](troubleshooting-safari-firestore.md).
