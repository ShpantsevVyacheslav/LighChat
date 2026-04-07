"use client";

import * as React from "react";
import { Input } from "@/components/ui/input";
import { cn } from "@/lib/utils";
import { applyPhoneMask, phoneStorageFromFormatted } from "@/lib/phone-utils";
import { tryApplyRuPhoneMaskKeyEdit } from "@/lib/ru-phone-mask-edit";

interface PhoneInputProps extends Omit<React.InputHTMLAttributes<HTMLInputElement>, "onChange" | "value"> {
  value?: string;
  onChange?: (value: string) => void;
  className?: string;
}

const PhoneInput = React.forwardRef<HTMLInputElement, PhoneInputProps>(
  ({ value = "", onChange, className, onKeyDown: onKeyDownProp, ...props }, ref) => {
    const [display, setDisplay] = React.useState(() => {
      if (value && value.length > 0) {
        const digits = value.replace(/\D/g, "");
        return digits.length > 0 ? applyPhoneMask(value) : "";
      }
      return "";
    });

    React.useEffect(() => {
      const digits = (value || "").replace(/\D/g, "");
      if (!digits) {
        setDisplay("");
        return;
      }
      setDisplay(applyPhoneMask(value || ""));
    }, [value]);

    const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
      const raw = e.target.value;

      if (raw === "" || raw === "+") {
        setDisplay("");
        onChange?.("");
        return;
      }

      const formatted = applyPhoneMask(raw);
      setDisplay(formatted);
      onChange?.(phoneStorageFromFormatted(formatted));
    };

    const handleKeyDown = (e: React.KeyboardEvent<HTMLInputElement>) => {
      const input = e.currentTarget;
      const start = input.selectionStart ?? 0;
      const end = input.selectionEnd ?? 0;
      const res = tryApplyRuPhoneMaskKeyEdit(e.key, display, start, end);
      if (!res) {
        onKeyDownProp?.(e);
        return;
      }
      e.preventDefault();
      setDisplay(res.display);
      onChange?.(phoneStorageFromFormatted(res.display));
      requestAnimationFrame(() => {
        input.setSelectionRange(res.caret, res.caret);
      });
    };

    const handleFocus = () => {
      if (!display) {
        setDisplay("+7(");
        onChange?.("+7");
      }
    };

    const handleBlur = () => {
      const digits = display.replace(/\D/g, "");
      if (digits.length <= 1) {
        setDisplay("");
        onChange?.("");
      }
    };

    return (
      <Input
        ref={ref}
        type="tel"
        inputMode="tel"
        value={display}
        onChange={handleChange}
        onKeyDown={handleKeyDown}
        onFocus={handleFocus}
        onBlur={handleBlur}
        placeholder="+7(909)418-96-53"
        className={cn(className)}
        {...props}
      />
    );
  }
);

PhoneInput.displayName = "PhoneInput";

export { PhoneInput };
