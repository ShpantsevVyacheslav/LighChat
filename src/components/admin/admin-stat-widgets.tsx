import React from 'react';

export function StatCard({ icon: Icon, label, value, color }: { icon: React.ElementType; label: string; value: number; color: string }) {
  return (
    <div className="rounded-2xl border p-4 flex items-center gap-3">
      <div className={`rounded-xl p-2.5 ${color}`}>
        <Icon className="h-5 w-5" />
      </div>
      <div>
        <p className="text-2xl font-bold">{value.toLocaleString('ru-RU')}</p>
        <p className="text-xs text-muted-foreground">{label}</p>
      </div>
    </div>
  );
}

export function MiniBarChart({ data, label }: { data: { date: string; value: number }[]; label: string }) {
  if (data.length === 0) return null;
  const max = Math.max(...data.map((d) => d.value), 1);
  // Если данных много (>14), число над столбцом сделает график шумным;
  // оставляем подписи только при <=14 столбцах. На длинных диапазонах
  // — только подсветка тултипа по hover, плюс ось снизу.
  const showInlineValues = data.length <= 14;
  // Минимальная видимая высота для bar'а со значением 0: показываем
  // тонкую серую полоску, чтобы день не выглядел «пропавшим».
  const ZERO_HEIGHT_PCT = 2;

  return (
    <div className="space-y-2">
      <p className="text-sm font-medium">{label}</p>
      <div className="flex items-end gap-[2px] h-[100px] relative">
        {data.map((d) => {
          const isZero = d.value === 0;
          const heightPct = isZero ? ZERO_HEIGHT_PCT : Math.max((d.value / max) * 100, 8);
          return (
            <div
              key={d.date}
              className="flex-1 flex flex-col items-center justify-end h-full group"
              title={`${d.date}: ${d.value}`}
            >
              {/* Inline-значение над столбцом, если позволяет ширина */}
              {showInlineValues && (
                <span
                  className={`text-[10px] leading-none mb-0.5 ${
                    isZero ? 'text-muted-foreground/60' : 'font-medium text-foreground'
                  }`}
                >
                  {d.value}
                </span>
              )}
              <div
                className={`w-full rounded-t-sm transition-colors ${
                  isZero
                    ? 'bg-muted-foreground/20'
                    : 'bg-primary/30 hover:bg-primary/60'
                }`}
                style={{ height: `${heightPct}%` }}
              />
            </div>
          );
        })}
      </div>
      {data.length > 0 && (
        <div className="flex justify-between text-[10px] text-muted-foreground">
          <span>{data[0].date.slice(5)}</span>
          <span>{data[data.length - 1].date.slice(5)}</span>
        </div>
      )}
    </div>
  );
}
