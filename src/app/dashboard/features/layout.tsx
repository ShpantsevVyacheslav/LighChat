import * as React from 'react';

export default function FeaturesLayout({ children }: { children: React.ReactNode }) {
  return (
    <div className="relative h-full w-full overflow-y-auto">
      <div className="mx-auto w-full max-w-6xl px-4 pb-16 pt-6 sm:px-6 lg:px-8">{children}</div>
    </div>
  );
}
