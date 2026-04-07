import { redirect } from 'next/navigation';

/** Список системных уведомлений отключён; старые ссылки ведут в чаты. */
export default function NotificationsPage() {
  redirect('/dashboard/chat');
}
