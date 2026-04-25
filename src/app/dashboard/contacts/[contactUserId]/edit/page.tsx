import { ContactEditClient } from '@/components/contacts/ContactEditClient';

export default async function ContactEditPage({
  params,
}: {
  params: Promise<{ contactUserId: string }>;
}) {
  const { contactUserId } = await params;
  return <ContactEditClient contactUserId={contactUserId} />;
}
