import type { Metadata } from 'next';
import * as React from 'react';

export const metadata: Metadata = {
  title: 'LighChat · Legal',
  robots: { index: true, follow: true },
};

export default function LegalLayout({ children }: { children: React.ReactNode }) {
  return (
    <div className="h-dvh w-full overflow-y-auto overflow-x-hidden bg-background text-foreground select-text">
      {children}
    </div>
  );
}
