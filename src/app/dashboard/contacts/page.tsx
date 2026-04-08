import { Suspense } from 'react';
import { Loader2 } from 'lucide-react';
import { ContactsClient } from '@/components/contacts/ContactsClient';

export default function ContactsPage() {
  return (
    <Suspense
      fallback={
        <div className="flex flex-1 items-center justify-center p-12 text-muted-foreground">
          <Loader2 className="h-8 w-8 animate-spin" aria-hidden />
        </div>
      }
    >
      <ContactsClient />
    </Suspense>
  );
}
