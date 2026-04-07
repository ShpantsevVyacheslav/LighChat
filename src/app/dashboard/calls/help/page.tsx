'use client';

import Link from 'next/link';
import { ArrowLeft, Phone, Video, Shield } from 'lucide-react';

/**
 * Справка по разделу «Звонки»: открывается со значка «?» на `/dashboard/calls`.
 */
export default function CallsHelpPage() {
  return (
    <div className="mx-auto flex h-full min-h-0 w-full max-w-2xl flex-col px-3 pb-6 pt-2">
      <Link
        href="/dashboard/calls"
        className="mb-4 inline-flex items-center gap-2 text-sm text-muted-foreground transition-colors hover:text-foreground"
      >
        <ArrowLeft className="h-4 w-4" />
        Назад к звонкам
      </Link>
      <h1 className="text-xl font-bold tracking-tight">Информация о звонках</h1>
      <p className="mt-2 text-sm text-muted-foreground">
        Кратко о том, как устроена история звонков и что отображается в сведениях о вызове.
      </p>

      <ul className="mt-6 space-y-5 text-sm leading-relaxed">
        <li className="flex gap-3 rounded-xl border border-border/60 bg-muted/30 p-4">
          <Phone className="mt-0.5 h-5 w-5 shrink-0 text-primary" />
          <div>
            <p className="font-semibold">Аудио и видео</p>
            <p className="mt-1 text-muted-foreground">
              Тип звонка отмечается иконкой телефона или камеры рядом со временем в списке. Кнопки быстрого
              набора позволяют снова начать аудио- или видеовызов с этим контактом.
            </p>
          </div>
        </li>
        <li className="flex gap-3 rounded-xl border border-border/60 bg-muted/30 p-4">
          <Video className="mt-0.5 h-5 w-5 shrink-0 text-primary" />
          <div>
            <p className="font-semibold">Сведения о звонке</p>
            <p className="mt-1 text-muted-foreground">
              При открытии карточки звонка фотография собеседника берётся из его текущего профиля, а не из
              снимка на момент прошлого вызова.
            </p>
          </div>
        </li>
        <li className="flex gap-3 rounded-xl border border-border/60 bg-muted/30 p-4">
          <Shield className="mt-0.5 h-5 w-5 shrink-0 text-primary" />
          <div>
            <p className="font-semibold">Конфиденциальность</p>
            <p className="mt-1 text-muted-foreground">
              В документе истории хранятся идентификаторы и служебные данные вызова; актуальные имя и аватар
              подгружаются из профиля пользователя при просмотре.
            </p>
          </div>
        </li>
      </ul>
    </div>
  );
}
