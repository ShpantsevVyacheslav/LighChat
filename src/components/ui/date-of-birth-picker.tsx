"use client";

import * as React from "react";
import { format, setMonth, setYear, isAfter, isBefore } from "date-fns";
import { ru } from "date-fns/locale";
import { CalendarIcon, ChevronLeft, ChevronRight } from "lucide-react";
import { DayPicker } from "react-day-picker";

import { cn } from "@/lib/utils";
import { Button, buttonVariants } from "@/components/ui/button";
import { Popover, PopoverContent, PopoverTrigger } from "@/components/ui/popover";

const MONTHS = [
  "Январь", "Февраль", "Март", "Апрель", "Май", "Июнь",
  "Июль", "Август", "Сентябрь", "Октябрь", "Ноябрь", "Декабрь",
];

const MIN_YEAR = 1920;
const MAX_DATE = new Date();

function generateYears(): number[] {
  const currentYear = new Date().getFullYear();
  const years: number[] = [];
  for (let y = currentYear; y >= MIN_YEAR; y--) {
    years.push(y);
  }
  return years;
}

const YEARS = generateYears();

interface DateOfBirthPickerProps {
  value?: string;
  onChange?: (value: string) => void;
  className?: string;
}

const DateOfBirthPicker = React.forwardRef<HTMLButtonElement, DateOfBirthPickerProps>(
  ({ value, onChange, className }, ref) => {
    const [open, setOpen] = React.useState(false);

    const selectedDate = React.useMemo(() => {
      if (!value) return undefined;
      const d = new Date(value);
      return isNaN(d.getTime()) ? undefined : d;
    }, [value]);

    const [displayMonth, setDisplayMonth] = React.useState<Date>(
      selectedDate || new Date(2000, 0, 1)
    );

    const handleSelect = (day: Date | undefined) => {
      if (!day) return;
      if (isAfter(day, MAX_DATE)) return;
      onChange?.(format(day, "yyyy-MM-dd"));
      setOpen(false);
    };

    const handleMonthChange = (e: React.ChangeEvent<HTMLSelectElement>) => {
      setDisplayMonth(setMonth(displayMonth, parseInt(e.target.value)));
    };

    const handleYearChange = (e: React.ChangeEvent<HTMLSelectElement>) => {
      setDisplayMonth(setYear(displayMonth, parseInt(e.target.value)));
    };

    const goToPrevMonth = () => {
      const prev = new Date(displayMonth);
      prev.setMonth(prev.getMonth() - 1);
      if (prev.getFullYear() >= MIN_YEAR) setDisplayMonth(prev);
    };

    const goToNextMonth = () => {
      const next = new Date(displayMonth);
      next.setMonth(next.getMonth() + 1);
      if (!isAfter(next, MAX_DATE)) setDisplayMonth(next);
    };

    const selectClass = "bg-secondary/80 text-foreground text-xs font-medium rounded-lg px-2 py-1.5 border-0 appearance-none cursor-pointer hover:bg-secondary";

    return (
      <Popover open={open} onOpenChange={setOpen}>
        <PopoverTrigger asChild>
          <Button
            ref={ref}
            type="button"
            variant="outline"
            className={cn(
              "w-full justify-start text-left font-normal border-border",
              !selectedDate && "text-muted-foreground",
              className
            )}
          >
            <CalendarIcon className="mr-2 h-4 w-4 opacity-50" />
            {selectedDate
              ? format(selectedDate, "d MMMM yyyy", { locale: ru })
              : "Выберите дату"}
          </Button>
        </PopoverTrigger>
        <PopoverContent className="w-auto p-0 rounded-2xl border-0 bg-card shadow-2xl" align="start">
          <div className="p-3">
            {/* Month/Year navigation */}
            <div className="flex items-center justify-between gap-1 mb-3">
              <Button type="button" variant="ghost" size="icon" className="h-8 w-8 rounded-full opacity-60 hover:opacity-100" onClick={goToPrevMonth}>
                <ChevronLeft className="h-4 w-4" />
              </Button>
              <div className="flex items-center gap-1.5">
                <select value={displayMonth.getMonth()} onChange={handleMonthChange} className={selectClass}>
                  {MONTHS.map((m, i) => (
                    <option key={i} value={i}>{m}</option>
                  ))}
                </select>
                <select value={displayMonth.getFullYear()} onChange={handleYearChange} className={selectClass}>
                  {YEARS.map((y) => (
                    <option key={y} value={y}>{y}</option>
                  ))}
                </select>
              </div>
              <Button type="button" variant="ghost" size="icon" className="h-8 w-8 rounded-full opacity-60 hover:opacity-100" onClick={goToNextMonth}>
                <ChevronRight className="h-4 w-4" />
              </Button>
            </div>

            {/* Calendar grid */}
            <DayPicker
              locale={ru}
              weekStartsOn={1}
              mode="single"
              selected={selectedDate}
              onSelect={handleSelect}
              month={displayMonth}
              onMonthChange={setDisplayMonth}
              disabled={{ after: MAX_DATE, before: new Date(MIN_YEAR, 0, 1) }}
              showOutsideDays
              hideNavigation
              className={cn(
                "[&_table]:table",
                "[&_thead]:table-header-group",
                "[&_tbody]:table-row-group",
                "[&_tr]:table-row",
                "[&_th]:table-cell",
                "[&_td]:table-cell",
              )}
              classNames={{
                months: "flex flex-col",
                month: "space-y-1",
                caption: "hidden",
                table: "w-full border-collapse",
                head_row: "flex",
                head_cell: "text-muted-foreground rounded-md w-9 font-medium text-[0.7rem] uppercase",
                row: "flex w-full mt-1",
                cell: "h-9 w-9 text-center text-sm p-0 relative",
                day: cn(
                  buttonVariants({ variant: "ghost" }),
                  "h-9 w-9 p-0 font-normal rounded-full hover:bg-primary/10 transition-colors"
                ),
                day_selected: "bg-primary text-primary-foreground hover:bg-primary hover:text-primary-foreground",
                day_today: "bg-accent/20 text-accent-foreground font-bold",
                day_outside: "text-muted-foreground opacity-30",
                day_disabled: "text-muted-foreground opacity-30",
                day_hidden: "invisible",
              }}
            />
          </div>
        </PopoverContent>
      </Popover>
    );
  }
);

DateOfBirthPicker.displayName = "DateOfBirthPicker";

export { DateOfBirthPicker };
