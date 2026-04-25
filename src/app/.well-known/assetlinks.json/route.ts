import { NextResponse } from 'next/server';

/** Совпадает с `applicationId` в mobile/app/android/app/build.gradle.kts */
const ANDROID_PACKAGE = 'com.lighchat.lighchat_mobile';

/**
 * SHA-256 отпечатки подписи APK (через запятую или пробел), без префикса `sha256:`.
 * Пример: `keytool -list -v -keystore …` или `cd mobile/app/android && ./gradlew signingReport`
 * Задайте в окружении деплоя: ANDROID_APP_LINK_SHA256_FINGERPRINTS
 */
function fingerprintList(): string[] {
  const raw = process.env.ANDROID_APP_LINK_SHA256_FINGERPRINTS ?? '';
  return raw
    .split(/[\s,]+/)
    .map((s) => s.trim().replace(/^sha256:/i, ''))
    .filter(Boolean);
}

export async function GET() {
  const sha256_cert_fingerprints = fingerprintList();

  if (sha256_cert_fingerprints.length === 0) {
    return NextResponse.json([], {
      headers: {
        'Content-Type': 'application/json',
        'Cache-Control': 'public, max-age=300',
      },
    });
  }

  return NextResponse.json(
    [
      {
        relation: ['delegate_permission/common.handle_all_urls'],
        target: {
          namespace: 'android_app',
          package_name: ANDROID_PACKAGE,
          sha256_cert_fingerprints,
        },
      },
    ],
    {
      headers: {
        'Content-Type': 'application/json',
        'Cache-Control': 'public, max-age=3600',
      },
    },
  );
}
