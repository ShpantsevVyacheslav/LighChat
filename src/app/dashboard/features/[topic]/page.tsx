'use client';

import * as React from 'react';
import { notFound, useParams } from 'next/navigation';
import { FeaturesTopicView } from '@/components/features/features-topic-view';
import {
  FEATURE_TOPICS_BY_ID,
  isFeatureTopicId,
} from '@/components/features/features-data';

export default function FeaturesTopicPage() {
  const params = useParams<{ topic: string }>();
  const raw = params?.topic;
  if (!raw || !isFeatureTopicId(raw)) {
    notFound();
  }
  const topic = FEATURE_TOPICS_BY_ID[raw];
  return <FeaturesTopicView topic={topic} />;
}
