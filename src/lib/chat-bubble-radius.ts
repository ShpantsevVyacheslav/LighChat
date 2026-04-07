import type { ChatSettings } from "@/lib/types";

export type BubbleRadiusValue = ChatSettings["bubbleRadius"];

/** Любые старые ключи из Firestore → скруглённые или квадратные */
const LEGACY_TO_VALUE: Record<string, BubbleRadiusValue> = {
  square: "square",
  sharp: "square",
  soft: "square",
  compact: "square",
  rounded: "rounded",
  loose: "rounded",
  "extra-rounded": "rounded",
  bubble: "rounded",
  pill: "rounded",
};

/** Скруглённые (как раньше) и квадратные (без скругления углов) */
export const BUBBLE_RADIUS_OPTIONS: ReadonlyArray<{
  value: BubbleRadiusValue;
  label: string;
  radius: string;
}> = [
  { value: "rounded", label: "Скруглённые", radius: "rounded-2xl" },
  { value: "square", label: "Квадратные", radius: "rounded-none" },
];

const RADIUS_CLASS_MAP: Record<BubbleRadiusValue, string> = {
  rounded: "rounded-2xl",
  square: "rounded-none",
};

export function normalizeBubbleRadius(
  raw: string | undefined | null
): BubbleRadiusValue {
  if (!raw) return "rounded";
  return LEGACY_TO_VALUE[raw] ?? "rounded";
}

export function bubbleRadiusToClass(radius: string | undefined | null): string {
  const v = normalizeBubbleRadius(radius);
  return RADIUS_CLASS_MAP[v] ?? "rounded-2xl";
}
