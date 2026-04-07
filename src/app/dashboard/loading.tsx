import { Icons } from "@/components/icons";

export default function Loading() {
  // Этот лоадер появляется поверх старого контента страницы во время навигации.
  // Абсолютное позиционирование + фон с блюром создают правильный эффект.
  return (
    <div className="absolute inset-0 z-[100] flex items-center justify-center bg-background/95 backdrop-blur-sm">
      <Icons.spinner className="h-8 w-8 animate-spin text-primary" />
    </div>
  );
}
