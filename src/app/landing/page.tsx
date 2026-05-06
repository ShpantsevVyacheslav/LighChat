import type { Metadata } from 'next';
import { LandingPage } from '@/components/landing/landing-page';

export const metadata: Metadata = {
  title: 'LighChat — мессенджер с шифрованием, играми и встречами',
  description:
    'LighChat: лёгкий мессенджер с E2EE на выбор, секретными чатами, отложенными сообщениями, видеовстречами и играми. Скачать в App Store и Google Play.',
};

export default function LandingRoutePage() {
  return <LandingPage />;
}
