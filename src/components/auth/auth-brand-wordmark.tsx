"use client";

import * as React from "react";
import { cn } from "@/lib/utils";

type WordmarkSize = "hero" | "compact" | "inline";

const sizeTitle: Record<WordmarkSize, string> = {
  hero: "text-2xl sm:text-3xl",
  compact: "text-xl sm:text-2xl",
  inline: "text-[1em] leading-none",
};

/**
 * Словесный знак LighChat в цветах фирменного LighTech: navy #1E3A5F, coral #E9967A.
 * Точка над «i» — отдельный круг того же coral, компактнее тела буквы (не «блок» сверху).
 */
export function AuthBrandWordmarkTitle({
  className,
  size = "hero",
  as: Tag = "h1",
}: {
  className?: string;
  size?: WordmarkSize;
  as?: "h1" | "h2" | "span" | "div";
}) {
  return (
    <Tag
      className={cn(
        "font-wordmark font-bold tracking-tight leading-none",
        sizeTitle[size],
        className
      )}
    >
      <span className="text-[#1E3A5F] dark:text-[#c5d9ed]">L</span>
      <span className="relative inline-block text-[#1E3A5F] dark:text-[#c5d9ed]">
        ı
        <span
          className="pointer-events-none absolute left-1/2 top-[0.1em] h-[0.17em] w-[0.17em] min-h-[2px] min-w-[2px] -translate-x-1/2 rounded-full bg-[#E9967A]"
          aria-hidden
        />
      </span>
      <span className="text-[#1E3A5F] dark:text-[#c5d9ed]">gh</span>
      <span className="text-[#E9967A]">Chat</span>
    </Tag>
  );
}

export function AuthBrandWordmarkBlock({
  children,
  className,
}: {
  children: React.ReactNode;
  className?: string;
}) {
  return <div className={cn("space-y-1 text-center", className)}>{children}</div>;
}

