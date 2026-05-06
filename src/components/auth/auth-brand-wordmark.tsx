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
      {/* "i" со встроенной coral-точкой — одной SVG-фигурой,
          чтобы исключить задвоение со штатной точкой шрифта. */}
      <svg
        aria-hidden
        viewBox="0 0 32 100"
        className="inline-block fill-[#1E3A5F] dark:fill-[#c5d9ed]"
        style={{ width: "0.30em", height: "1em", verticalAlign: "baseline" }}
      >
        {/* stem от x-height (48) до baseline (96) — как у "g" / "L" */}
        <rect x="7" y="48" width="18" height="48" rx="9" />
        {/* coral dot — диаметр ≈ stem width, центрирован над stem */}
        <circle cx="16" cy="22" r="9.6" fill="#E9967A" />
      </svg>
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

