'use client';

import { UserSupportForm } from '@/components/support/user-support-form';
import { AnnouncementBanner } from '@/components/announcements/announcement-banner';

export default function SupportPage() {
  return (
    <div className="mx-auto max-w-lg space-y-6 p-4">
      <AnnouncementBanner />
      <UserSupportForm />
    </div>
  );
}
