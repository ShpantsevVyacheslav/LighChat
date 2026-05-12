"use client";

import * as React from "react";
import { cn } from "@/lib/utils";

type WordmarkSize = "hero" | "compact" | "inline";

const sizeTitle: Record<WordmarkSize, string> = {
  hero: "text-2xl sm:text-3xl",
  compact: "text-xl sm:text-2xl",
  inline: "text-[1em] leading-none",
};

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
        "font-wordmark font-extrabold tracking-tight leading-none",
        sizeTitle[size],
        className
      )}
    >
      <span className="text-[#1E3A5F] dark:text-[#c5d9ed]">Ligh</span>
      <span className="text-[#F4A12C]">Chat</span>
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
