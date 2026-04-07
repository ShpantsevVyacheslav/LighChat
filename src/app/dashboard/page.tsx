"use client";

import { useEffect } from "react";
import { useRouter } from "next/navigation";
import { Icons } from "@/components/icons";

export default function DashboardPage() {
  const router = useRouter();

  useEffect(() => {
    router.replace("/dashboard/chat");
  }, [router]);

  return (
    <div className="flex h-[60vh] items-center justify-center">
      <Icons.spinner className="h-8 w-8 animate-spin text-primary" />
    </div>
  );
}
