'use client';

import React, { createContext, useContext, useMemo } from 'react';

export type VideoCircleTailContextValue = {
  /** Дополнительная высота футера Virtuoso (px), чтобы последний развёрнутый кружок помещался над полем ввода. */
  setTailReservePx: (px: number) => void;
};

const VideoCircleTailContext = createContext<VideoCircleTailContextValue | null>(null);

export function VideoCircleTailProvider({
  children,
  setTailReservePx,
}: {
  children: React.ReactNode;
  setTailReservePx: (px: number) => void;
}) {
  const value = useMemo(() => ({ setTailReservePx }), [setTailReservePx]);
  return (
    <VideoCircleTailContext.Provider value={value}>
      {children}
    </VideoCircleTailContext.Provider>
  );
}

export function useVideoCircleTailOptional(): VideoCircleTailContextValue | null {
  return useContext(VideoCircleTailContext);
}
