'use client';

import * as React from 'react';

/**
 * Лёгкий хук-обёртка над `window.speechSynthesis` для showreel-озвучки.
 *
 *  – `speak(text, lang)` отменяет текущее воспроизведение и стартует новое;
 *  – `pause()` / `resume()` — pause/resume системной очереди;
 *  – `cancel()` — очищает очередь, важно при unmount и закрытии плеера;
 *  – `setMuted(true)` — глушит speech (через cancel + флаг);
 *  – `supported` — false, если браузер не имеет Web Speech API
 *    (показываем showreel молча, с субтитрами).
 *
 * Голос подбирается из доступных по `lang.startsWith('ru'|'en')` —
 * предпочтительно с `lang === ${tag}` для точного матча.
 */
export function useShowreelTts() {
  const [supported, setSupported] = React.useState(false);
  const [muted, setMuted] = React.useState(false);
  const voicesRef = React.useRef<SpeechSynthesisVoice[]>([]);

  React.useEffect(() => {
    if (typeof window === 'undefined') return;
    if (!('speechSynthesis' in window)) return;
    setSupported(true);
    // voiceschanged срабатывает асинхронно у Chrome/Edge.
    const loadVoices = () => {
      voicesRef.current = window.speechSynthesis.getVoices();
    };
    loadVoices();
    window.speechSynthesis.addEventListener?.('voiceschanged', loadVoices);
    return () => {
      window.speechSynthesis.removeEventListener?.('voiceschanged', loadVoices);
      try {
        window.speechSynthesis.cancel();
      } catch {
        /* ignore */
      }
    };
  }, []);

  const pickVoice = React.useCallback((lang: string): SpeechSynthesisVoice | undefined => {
    const voices = voicesRef.current;
    if (voices.length === 0) return undefined;
    const exact = voices.find((v) => v.lang === lang);
    if (exact) return exact;
    const tag = lang.split('-')[0];
    return voices.find((v) => v.lang.startsWith(tag));
  }, []);

  const speak = React.useCallback(
    (text: string, lang = 'ru-RU') => {
      if (!supported || muted || typeof window === 'undefined') return;
      try {
        window.speechSynthesis.cancel();
      } catch {
        /* ignore */
      }
      const utter = new SpeechSynthesisUtterance(text);
      utter.lang = lang;
      utter.rate = 1.0;
      utter.pitch = 1.0;
      utter.volume = 1.0;
      const voice = pickVoice(lang);
      if (voice) utter.voice = voice;
      try {
        window.speechSynthesis.speak(utter);
      } catch {
        /* ignore */
      }
    },
    [supported, muted, pickVoice],
  );

  const cancel = React.useCallback(() => {
    if (!supported || typeof window === 'undefined') return;
    try {
      window.speechSynthesis.cancel();
    } catch {
      /* ignore */
    }
  }, [supported]);

  const pause = React.useCallback(() => {
    if (!supported || typeof window === 'undefined') return;
    try {
      window.speechSynthesis.pause();
    } catch {
      /* ignore */
    }
  }, [supported]);

  const resume = React.useCallback(() => {
    if (!supported || typeof window === 'undefined') return;
    try {
      window.speechSynthesis.resume();
    } catch {
      /* ignore */
    }
  }, [supported]);

  const toggleMute = React.useCallback(() => {
    setMuted((m) => {
      const next = !m;
      if (next && typeof window !== 'undefined' && supported) {
        try {
          window.speechSynthesis.cancel();
        } catch {
          /* ignore */
        }
      }
      return next;
    });
  }, [supported]);

  return { supported, muted, speak, cancel, pause, resume, toggleMute };
}
