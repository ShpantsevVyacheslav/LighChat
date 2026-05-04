'use client';

import * as React from 'react';
import { useSearchParams } from 'next/navigation';
import { FeaturesIndexGrid } from '@/components/features/features-index-grid';

export default function FeaturesIndexPage() {
  const search = useSearchParams();
  const source = search?.get('source') ?? undefined;
  return <FeaturesIndexGrid source={source} />;
}
