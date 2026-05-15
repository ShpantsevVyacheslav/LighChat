import type {Config} from 'tailwindcss';

export default {
  darkMode: ['class'],
  content: [
    './src/pages/**/*.{js,ts,jsx,tsx,mdx}',
    './src/components/**/*.{js,ts,jsx,tsx,mdx}',
    './src/app/**/*.{js,ts,jsx,tsx,mdx}',
  ],
  theme: {
    extend: {
      fontFamily: {
        body: ['var(--font-inter)', 'sans-serif'],
        headline: ['var(--font-space-grotesk)', 'sans-serif'],
        /** Геометрический гротеск для словесного знака (как на фирменном логотипе) */
        wordmark: ['var(--font-outfit)', 'var(--font-inter)', 'sans-serif'],
        code: ['monospace'],
      },
      colors: {
        background: 'hsl(var(--background))',
        foreground: 'hsl(var(--foreground))',
        card: {
          DEFAULT: 'hsl(var(--card))',
          foreground: 'hsl(var(--card-foreground))',
        },
        popover: {
          DEFAULT: 'hsl(var(--popover))',
          foreground: 'hsl(var(--popover-foreground))',
        },
        primary: {
          DEFAULT: 'hsl(var(--primary))',
          foreground: 'hsl(var(--primary-foreground))',
        },
        secondary: {
          DEFAULT: 'hsl(var(--secondary))',
          foreground: 'hsl(var(--secondary-foreground))',
        },
        muted: {
          DEFAULT: 'hsl(var(--muted))',
          foreground: 'hsl(var(--muted-foreground))',
        },
        accent: {
          DEFAULT: 'hsl(var(--accent))',
          foreground: 'hsl(var(--accent-foreground))',
        },
        destructive: {
          DEFAULT: 'hsl(var(--destructive))',
          foreground: 'hsl(var(--destructive-foreground))',
        },
        border: 'hsl(var(--border))',
        input: 'hsl(var(--input))',
        ring: 'hsl(var(--ring))',
        chart: {
          '1': 'hsl(var(--chart-1))',
          '2': 'hsl(var(--chart-2))',
          '3': 'hsl(var(--chart-3))',
          '4': 'hsl(var(--chart-4))',
          '5': 'hsl(var(--chart-5))',
        },
        sidebar: {
          DEFAULT: 'hsl(var(--sidebar-background))',
          foreground: 'hsl(var(--sidebar-foreground))',
          primary: 'hsl(var(--sidebar-primary))',
          'primary-foreground': 'hsl(var(--sidebar-primary-foreground))',
          accent: 'hsl(var(--sidebar-accent))',
          'accent-foreground': 'hsl(var(--sidebar-accent-foreground))',
          border: 'hsl(var(--sidebar-border))',
          ring: 'hsl(var(--sidebar-ring))',
        },
        'outgoing-message': {
          DEFAULT: 'hsl(var(--outgoing-message-background))',
          foreground: 'hsl(var(--outgoing-message-foreground))',
          accent: 'hsl(var(--outgoing-message-accent))',
        },
        /** Словесный знак: тёмно-синий + тёплый оранж (цвет маяка в фирменном логотипе) */
        brand: {
          navy: '#1E3A5F',
          orange: '#F4A12C',
        },
      },
      borderRadius: {
        lg: 'var(--radius)',
        md: 'calc(var(--radius) - 2px)',
        sm: 'calc(var(--radius) - 4px)',
        '3xl': '1.5rem',
      },
      keyframes: {
        'accordion-down': {
          from: {
            height: '0',
          },
          to: {
            height: 'var(--radix-accordion-content-height)',
          },
        },
        'accordion-up': {
          from: {
            height: 'var(--radix-accordion-content-height)',
          },
          to: {
            height: '0',
          },
        },
        /** Сообщение «всплывает» снизу с лёгким сдвигом — для мокапов в Возможностях. */
        'feat-bubble-in': {
          '0%': { opacity: '0', transform: 'translateY(8px) scale(0.96)' },
          '60%': { opacity: '1' },
          '100%': { opacity: '1', transform: 'translateY(0) scale(1)' },
        },
        /** Растворение исчезающего сообщения. */
        'feat-fade-vanish': {
          '0%, 70%': { opacity: '0.55', filter: 'blur(0px)' },
          '100%': { opacity: '0.05', filter: 'blur(2px)' },
        },
        /** «Тикающая» точка таймера. */
        'feat-timer-tick': {
          '0%, 49%': { transform: 'rotate(0deg)' },
          '50%, 100%': { transform: 'rotate(180deg)' },
        },
        /** Бегущий чёрный модуль QR. */
        'feat-qr-scan': {
          '0%, 100%': { transform: 'translateY(0)', opacity: '0.6' },
          '50%': { transform: 'translateY(56px)', opacity: '1' },
        },
        /** Эквалайзер — пульсация по полосам. */
        'feat-eq-1': {
          '0%, 100%': { height: '4px' },
          '50%': { height: '12px' },
        },
        'feat-eq-2': {
          '0%, 100%': { height: '8px' },
          '50%': { height: '16px' },
        },
        'feat-eq-3': {
          '0%, 100%': { height: '12px' },
          '50%': { height: '6px' },
        },
        'feat-eq-4': {
          '0%, 100%': { height: '6px' },
          '50%': { height: '14px' },
        },
        /** Лёгкое «дыхание» подсветки активного спикера во встрече. */
        'feat-speaker-pulse': {
          '0%, 100%': { boxShadow: '0 0 0 0 hsl(160 84% 50% / 0.6)' },
          '50%': { boxShadow: '0 0 0 6px hsl(160 84% 50% / 0)' },
        },
        /** Пульсирующий пин на карте. */
        'feat-pin-pulse': {
          '0%': { transform: 'scale(1)', opacity: '0.7' },
          '100%': { transform: 'scale(2.6)', opacity: '0' },
        },
        /** Мигающий курсор в строке ввода. */
        'feat-caret': {
          '0%, 49%': { opacity: '1' },
          '50%, 100%': { opacity: '0' },
        },
        /** Печатающий индикатор: 3 точки. */
        'feat-typing-1': {
          '0%, 80%, 100%': { transform: 'translateY(0)', opacity: '0.4' },
          '40%': { transform: 'translateY(-3px)', opacity: '1' },
        },
        /** Карта «Дурака» появляется и поворачивается в веер. */
        'feat-card-deal': {
          '0%': { opacity: '0', transform: 'translate(-20px, 30px) rotate(0deg)' },
          '100%': { opacity: '1' },
        },
        /** Бесконечно ползущий dash-контур секретного бабла. */
        'feat-dash-march': {
          '0%': { strokeDashoffset: '0' },
          '100%': { strokeDashoffset: '12' },
        },
        /** Подсветка кнопки «отправить» расписания. */
        'feat-clock-glow': {
          '0%, 100%': { boxShadow: '0 0 0 0 hsl(var(--primary) / 0.4)' },
          '50%': { boxShadow: '0 0 0 6px hsl(var(--primary) / 0)' },
        },
        /** Mock «свайп» переключателя приватности. */
        'feat-switch-toggle': {
          '0%, 45%': { transform: 'translateX(2px)' },
          '55%, 100%': { transform: 'translateX(18px)' },
        },
        /** Hovering subtle plates motion на hero. */
        'feat-float-1': {
          '0%, 100%': { transform: 'translateY(0) rotate(-3deg)' },
          '50%': { transform: 'translateY(-6px) rotate(-3deg)' },
        },
        'feat-float-2': {
          '0%, 100%': { transform: 'translateY(0) rotate(2deg)' },
          '50%': { transform: 'translateY(-4px) rotate(2deg)' },
        },
        'feat-float-3': {
          '0%, 100%': { transform: 'translateY(0) rotate(-1deg)' },
          '50%': { transform: 'translateY(-5px) rotate(-1deg)' },
        },
        /** Бегущая лента шифр-данных — слева направо, бесконечно. */
        'feat-cipher-stream': {
          '0%': { transform: 'translateX(-50%)' },
          '100%': { transform: 'translateX(0%)' },
        },
        /** Мерцание hex-символа в потоке (3 фазы). */
        'feat-cipher-flicker': {
          '0%, 100%': { opacity: '0.85' },
          '33%': { opacity: '0.45' },
          '66%': { opacity: '1' },
        },
        /** «Шифрование»: замок поворачивается из открытого в закрытое и обратно. */
        'feat-lock-cycle': {
          '0%, 30%': { transform: 'rotate(0deg) scale(1)' },
          '50%, 70%': { transform: 'rotate(0deg) scale(1.08)' },
          '100%': { transform: 'rotate(0deg) scale(1)' },
        },
        /** Сообщение «отлетает» от отправителя в сторону потока шифрования. */
        'feat-msg-fly-right': {
          '0%, 25%': { transform: 'translateX(0)', opacity: '1' },
          '40%': { transform: 'translateX(20px)', opacity: '0' },
          '40.01%, 100%': { opacity: '0' },
        },
        /** Сообщение «прилетает» к получателю из потока. */
        'feat-msg-fly-in': {
          '0%, 60%': { transform: 'translateX(-20px)', opacity: '0' },
          '75%, 100%': { transform: 'translateX(0)', opacity: '1' },
        },
        /** Бегущая стрелочка под потоком — пунктирный «traffic». */
        'feat-arrow-pulse': {
          '0%, 100%': { opacity: '0.3' },
          '50%': { opacity: '1' },
        },
        /**
         * Атакующая карта в Дураке: 0% — невидима возле руки внизу,
         * 6% — на своём слоте на столе, 80% — стоит, 88% — улетает к
         * проигравшему (вверх-вправо к аватару оппонента), 100% — невидима.
         * Цикл подбирается у каждой карты через animation-delay.
         */
        'feat-durak-attack': {
          '0%': { transform: 'translate(0, 60px) rotate(-6deg)', opacity: '0' },
          '6%': { transform: 'translate(0, 0) rotate(0deg)', opacity: '1' },
          '80%': { transform: 'translate(0, 0) rotate(0deg)', opacity: '1' },
          '92%': { transform: 'translate(60px, -90px) rotate(20deg) scale(0.55)', opacity: '0' },
          '100%': { transform: 'translate(60px, -90px) rotate(20deg) scale(0.55)', opacity: '0' },
        },
        /** Защитная карта: появляется со смещением сверху, сдвинута относительно атакующей. */
        'feat-durak-defend': {
          '0%, 8%': { transform: 'translate(8px, -40px) rotate(8deg)', opacity: '0' },
          '14%': { transform: 'translate(8px, 6px) rotate(8deg)', opacity: '1' },
          '80%': { transform: 'translate(8px, 6px) rotate(8deg)', opacity: '1' },
          '92%': { transform: 'translate(70px, -84px) rotate(28deg) scale(0.55)', opacity: '0' },
          '100%': { transform: 'translate(70px, -84px) rotate(28deg) scale(0.55)', opacity: '0' },
        },
        /** Аватар «забирающего» подсвечивается на финальной фазе (90-100%). */
        'feat-durak-loser-glow': {
          '0%, 84%': { boxShadow: '0 0 0 0 rgba(248,113,113,0)' },
          '92%': { boxShadow: '0 0 0 6px rgba(248,113,113,0.45)' },
          '100%': { boxShadow: '0 0 0 0 rgba(248,113,113,0)' },
        },
        /** Подсветка слота на столе (плейсхолдер «+»): пульсирует между 90-100%. */
        'feat-durak-slot-empty': {
          '0%, 84%': { opacity: '0' },
          '92%': { opacity: '1' },
          '100%': { opacity: '0' },
        },
        /** Live-location trail: dash-offset рисует линию от 0 до 100% длины,
         *  потом ждёт и сбрасывается. */
        'feat-live-trail': {
          '0%': { strokeDashoffset: '300' },
          '70%': { strokeDashoffset: '0' },
          '95%': { strokeDashoffset: '0' },
          '100%': { strokeDashoffset: '300' },
        },
        /** Live-location pin: движется по offset-path от 0 до 100% и
         *  возвращается. */
        'feat-live-pin': {
          '0%': { offsetDistance: '0%' },
          '70%': { offsetDistance: '100%' },
          '95%': { offsetDistance: '100%' },
          '100%': { offsetDistance: '0%' },
        },
        /** Лёгкий Ken-Burns зум на сцене showreel: 1.0 → 1.06 за сцену. */
        'feat-ken-burns': {
          '0%': { transform: 'scale(1)' },
          '100%': { transform: 'scale(1.06)' },
        },
      },
      animation: {
        'accordion-down': 'accordion-down 0.2s ease-out',
        'accordion-up': 'accordion-up 0.2s ease-out',
        'feat-bubble-in': 'feat-bubble-in 0.6s cubic-bezier(0.16, 1, 0.3, 1) both',
        'feat-fade-vanish': 'feat-fade-vanish 4s ease-in-out infinite',
        'feat-timer-tick': 'feat-timer-tick 2s steps(1, end) infinite',
        'feat-qr-scan': 'feat-qr-scan 2.4s ease-in-out infinite',
        'feat-eq-1': 'feat-eq-1 0.9s ease-in-out infinite',
        'feat-eq-2': 'feat-eq-2 1.1s ease-in-out infinite',
        'feat-eq-3': 'feat-eq-3 0.8s ease-in-out infinite',
        'feat-eq-4': 'feat-eq-4 1.2s ease-in-out infinite',
        'feat-speaker-pulse': 'feat-speaker-pulse 2s ease-out infinite',
        'feat-pin-pulse': 'feat-pin-pulse 2.4s ease-out infinite',
        'feat-caret': 'feat-caret 1s steps(1, end) infinite',
        'feat-typing': 'feat-typing-1 1.2s ease-in-out infinite',
        'feat-card-deal': 'feat-card-deal 0.6s cubic-bezier(0.16, 1, 0.3, 1) both',
        'feat-dash-march': 'feat-dash-march 0.6s linear infinite',
        'feat-clock-glow': 'feat-clock-glow 2s ease-out infinite',
        'feat-switch-toggle': 'feat-switch-toggle 3s ease-in-out infinite',
        'feat-float-1': 'feat-float-1 6s ease-in-out infinite',
        'feat-float-2': 'feat-float-2 7s ease-in-out infinite',
        'feat-float-3': 'feat-float-3 8s ease-in-out infinite',
        'feat-cipher-stream': 'feat-cipher-stream 6s linear infinite',
        'feat-cipher-flicker': 'feat-cipher-flicker 1.6s ease-in-out infinite',
        'feat-lock-cycle': 'feat-lock-cycle 4s ease-in-out infinite',
        'feat-msg-fly-right': 'feat-msg-fly-right 4s ease-in-out infinite',
        'feat-msg-fly-in': 'feat-msg-fly-in 4s ease-in-out infinite',
        'feat-arrow-pulse': 'feat-arrow-pulse 1.4s ease-in-out infinite',
        /** Цикл партии в «Дурака»: ~10s, согласован у атаки/защиты/glow. */
        'feat-durak-attack': 'feat-durak-attack 10s ease-in-out infinite',
        'feat-durak-defend': 'feat-durak-defend 10s ease-in-out infinite',
        'feat-durak-loser-glow': 'feat-durak-loser-glow 10s ease-out infinite',
        'feat-durak-slot-empty': 'feat-durak-slot-empty 10s linear infinite',
        /** Live-location: trail + бегущий пин — 16s цикл, согласованы. */
        'feat-live-trail': 'feat-live-trail 16s ease-in-out infinite',
        'feat-live-pin': 'feat-live-pin 16s ease-in-out infinite',
        /** Showreel: лёгкий Ken-Burns на длительность одной сцены (~12s). */
        'feat-ken-burns': 'feat-ken-burns 12s ease-out forwards',
      },
    },
  },
  plugins: [require('tailwindcss-animate')],
} satisfies Config;
