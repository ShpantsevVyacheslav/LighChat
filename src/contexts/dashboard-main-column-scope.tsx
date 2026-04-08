"use client";

import * as React from "react";

type DashboardMainColumnScopeValue = {
  getElement: () => HTMLElement | null;
};

const DashboardMainColumnScopeContext = React.createContext<DashboardMainColumnScopeValue | null>(null);

/**
 * Даёт потомкам (например, оверлею обрезки аватара на профиле) доступ к DOM правой колонки дашборда
 * — контент под списком чатов, без боковой панели.
 */
export function DashboardMainColumnScopeProvider({
  children,
  mainColumnRef,
}: {
  children: React.ReactNode;
  mainColumnRef: React.RefObject<HTMLElement | null>;
}) {
  const value = React.useMemo(
    () => ({
      getElement: () => mainColumnRef.current,
    }),
    [mainColumnRef],
  );
  return (
    <DashboardMainColumnScopeContext.Provider value={value}>{children}</DashboardMainColumnScopeContext.Provider>
  );
}

export function useDashboardMainColumnScope(): (() => HTMLElement | null) | null {
  const ctx = React.useContext(DashboardMainColumnScopeContext);
  return ctx ? ctx.getElement : null;
}
