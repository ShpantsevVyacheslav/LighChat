"use client"

import { useToast } from "@/hooks/use-toast"
import {
  Toast,
  ToastClose,
  ToastDescription,
  ToastProvider,
  ToastTitle,
  ToastViewport,
} from "@/components/ui/toast"

/** Автоскрытие toast-уведомлений по умолчанию (мс). Отдельный вызов может задать свой `duration`. */
const TOAST_AUTO_DISMISS_MS = 2000

export function Toaster() {
  const { toasts } = useToast()

  return (
    <ToastProvider duration={TOAST_AUTO_DISMISS_MS}>
      {toasts.map(function ({ id, title, description, action, ...props }) {
        return (
          <Toast key={id} {...props}>
            <div className="grid gap-1">
              {title && <ToastTitle>{title}</ToastTitle>}
              {description && (
                <ToastDescription>{description}</ToastDescription>
              )}
            </div>
            {action}
            <ToastClose />
          </Toast>
        )
      })}
      <ToastViewport />
    </ToastProvider>
  )
}
