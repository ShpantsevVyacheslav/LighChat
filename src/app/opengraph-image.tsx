import { ImageResponse } from 'next/og';

export const runtime = 'edge';

export const alt = 'LighChat — безопасный мессенджер с шифрованием и QR-входом';
export const size = { width: 1200, height: 630 };
export const contentType = 'image/png';

export default async function OpenGraphImage() {
  /** Фирменный знак — маяк в чат-пузыре. Файл лежит рядом, чтобы edge runtime мог его подхватить. */
  const markData = await fetch(new URL('./_og-mark.png', import.meta.url)).then(
    (res) => res.arrayBuffer(),
  );
  const markSrc = `data:image/png;base64,${Buffer.from(markData).toString('base64')}`;

  return new ImageResponse(
    (
      <div
        style={{
          width: '100%',
          height: '100%',
          display: 'flex',
          flexDirection: 'column',
          justifyContent: 'space-between',
          background:
            'linear-gradient(135deg, #0a0e17 0%, #131a2c 55%, #1f2a4a 100%)',
          padding: '80px',
          fontFamily: 'sans-serif',
        }}
      >
        <div
          style={{
            display: 'flex',
            alignItems: 'center',
            gap: '24px',
            color: '#ffffff',
            fontSize: '64px',
            fontWeight: 700,
            letterSpacing: '-0.02em',
          }}
        >
          {/* eslint-disable-next-line @next/next/no-img-element */}
          <img
            src={markSrc}
            width={104}
            height={104}
            alt=""
            style={{ display: 'block' }}
          />
          LighChat
        </div>

        <div style={{ display: 'flex', flexDirection: 'column', gap: '24px' }}>
          <div
            style={{
              color: '#ffffff',
              fontSize: '72px',
              fontWeight: 800,
              lineHeight: 1.1,
              letterSpacing: '-0.02em',
              maxWidth: '900px',
            }}
          >
            Безопасный мессенджер с QR-входом
          </div>
          <div
            style={{
              color: '#a5b4fc',
              fontSize: '32px',
              fontWeight: 500,
              maxWidth: '900px',
              lineHeight: 1.3,
            }}
          >
            E2E-шифрование · Мульти-девайс · HD-видеозвонки · Кастомные темы
          </div>
        </div>

        <div
          style={{
            display: 'flex',
            justifyContent: 'space-between',
            alignItems: 'flex-end',
            color: '#94a3b8',
            fontSize: '26px',
            fontWeight: 500,
          }}
        >
          <div style={{ display: 'flex', gap: '12px' }}>
            <span>iOS</span>
            <span>·</span>
            <span>Android</span>
            <span>·</span>
            <span>Web</span>
            <span>·</span>
            <span>Desktop</span>
          </div>
          <div style={{ color: '#cbd5e1' }}>lighchat.online</div>
        </div>
      </div>
    ),
    size,
  );
}
