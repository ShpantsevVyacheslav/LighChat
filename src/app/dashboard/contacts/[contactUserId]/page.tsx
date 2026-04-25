import { ContactProfileClient } from '@/components/contacts/ContactProfileClient';

export default async function ContactProfilePage({
  params,
}: {
  params: Promise<{ contactUserId: string }>;
}) {
  const { contactUserId } = await params;
  return <ContactProfileClient contactUserId={contactUserId} />;
}
