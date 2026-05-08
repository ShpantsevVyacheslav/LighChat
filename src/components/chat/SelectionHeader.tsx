'use client';

import { Button } from '@/components/ui/button';
import { Tooltip, TooltipContent, TooltipProvider, TooltipTrigger } from '@/components/ui/tooltip';
import { Loader2, X, Forward, Trash } from 'lucide-react';
import { useI18n } from '@/hooks/use-i18n';

export function SelectionHeader({ count, onCancel, onDelete, onForward, isProcessing, showDelete }: { count: number; onCancel: () => void; onDelete: () => void; onForward: () => void; isProcessing: boolean; showDelete: boolean; }) {
  const { t } = useI18n();
  return (
    <div className="flex items-center justify-between w-full h-full animate-in fade-in slide-in-from-top-4 duration-300">
      <Button variant="ghost" onClick={onCancel} disabled={isProcessing} className="rounded-full hover:bg-foreground/5 h-10 px-4">
        <X className="mr-2 h-4 w-4" /> {t('chat.selection.cancel')}
      </Button>

      <span className="font-bold text-sm">{t('chat.selection.selected', { count: String(count) })}</span>

      <div className="flex items-center gap-1">
        <TooltipProvider>
          <Tooltip>
            <TooltipTrigger asChild>
              <Button variant="ghost" size="icon" onClick={onForward} disabled={count === 0 || isProcessing} className="rounded-full text-primary hover:bg-primary/10 h-10 w-10">
                <Forward className="h-5 w-5" />
              </Button>
            </TooltipTrigger>
            <TooltipContent><p>{t('chat.selection.forward')}</p></TooltipContent>
          </Tooltip>

          {showDelete && (
            <Tooltip>
              <TooltipTrigger asChild>
                <Button variant="ghost" size="icon" onClick={onDelete} disabled={count === 0 || isProcessing} className="rounded-full text-destructive hover:bg-destructive/10 h-10 w-10">
                  {isProcessing ? <Loader2 className="h-5 w-5 animate-spin" /> : <Trash className="h-5 w-5" />}
                </Button>
              </TooltipTrigger>
              <TooltipContent><p>{t('chat.selection.delete')}</p></TooltipContent>
            </Tooltip>
          )}
        </TooltipProvider>
      </div>
    </div>
  );
}