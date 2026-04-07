'use client';

import React, {
  createContext,
  useCallback,
  useContext,
  useMemo,
  useState,
} from 'react';

type MobileChatOpenContextValue = {
  /** На мобильном открыт экран переписки (не список диалогов). */
  mobileConversationOpen: boolean;
  setMobileConversationOpen: (open: boolean) => void;
};

const MobileChatOpenContext = createContext<MobileChatOpenContextValue | null>(
  null
);

export function MobileChatOpenProvider({
  children,
}: {
  children: React.ReactNode;
}) {
  const [mobileConversationOpen, setOpen] = useState(false);
  const setMobileConversationOpen = useCallback((open: boolean) => {
    setOpen(open);
  }, []);
  const value = useMemo(
    () => ({ mobileConversationOpen, setMobileConversationOpen }),
    [mobileConversationOpen, setMobileConversationOpen]
  );
  return (
    <MobileChatOpenContext.Provider value={value}>
      {children}
    </MobileChatOpenContext.Provider>
  );
}

export function useMobileChatOpenOptional() {
  return useContext(MobileChatOpenContext);
}
