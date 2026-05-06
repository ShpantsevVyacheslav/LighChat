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

  return (
    <div className="space-y-2">
      <p className="text-sm font-medium">{label}</p>
      <div className="flex items-end gap-[2px] h-[80px]">
        {data.map((d) => (
          <div
            key={d.date}
            className="flex-1 bg-primary/20 hover:bg-primary/40 transition-colors rounded-t-sm relative group"
            style={{ height: `${Math.max((d.value / max) * 100, 4)}%` }}
          >
            <div className="absolute bottom-full left-1/2 -translate-x-1/2 mb-1 hidden group-hover:block bg-popover text-popover-foreground text-[10px] px-1.5 py-0.5 rounded shadow whitespace-nowrap z-10">
              {d.date}: {d.value}
            </div>
          </div>
        ))}
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
