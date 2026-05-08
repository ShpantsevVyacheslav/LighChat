'use client';

import React, { useState, useRef } from 'react';
import { Paperclip, Send, X, Loader2, Edit } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { cn } from '@/lib/utils';
import { useI18n } from '@/hooks/use-i18n';

interface MeetingChatMessageInputProps {
  value: string;
  onChange: (value: string) => void;
  onSend: (text: string, files: File[]) => Promise<void>;
  isUploading: boolean;
  editingMessage: any | null;
  onCancelEdit: () => void;
}

export function MeetingChatMessageInput({
  value,
  onChange,
  onSend,
  isUploading,
  editingMessage,
  onCancelEdit
}: MeetingChatMessageInputProps) {
  const { t } = useI18n();
  const [attachments, setAttachments] = useState<File[]>([]);
  const [previews, setPreviews] = useState<string[]>([]);
  const fileInputRef = useRef<HTMLInputElement>(null);

  const handleFileSelect = (e: React.ChangeEvent<HTMLInputElement>) => {
    const files = Array.from(e.target.files || []);
    if (files.length === 0) return;
    setAttachments(prev => [...prev, ...files]);
    setPreviews(prev => [...prev, ...files.map(f => URL.createObjectURL(f))]);
  };

  const removeAttachment = (index: number) => {
    setAttachments(prev => prev.filter((_, i) => i !== index));
    setPreviews(prev => {
      URL.revokeObjectURL(prev[index]);
      return prev.filter((_, i) => i !== index);
    });
  };

  const handlePaste = (e: React.ClipboardEvent) => {
    const items = Array.from(e.clipboardData.items);
    const imageFiles = items
      .filter(item => item.type.startsWith('image/'))
      .map(item => item.getAsFile())
      .filter((file): file is File => file !== null);
    
    if (imageFiles.length > 0) {
      e.preventDefault();
      setAttachments(prev => [...prev, ...imageFiles]);
      setPreviews(prev => [...prev, ...imageFiles.map(f => URL.createObjectURL(f))]);
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (isUploading) return;
    
    const textToSend = value;
    const filesToSend = [...attachments];

    // МГНОВЕННО очищаем строку ввода и вложения в UI
    onChange('');
    setAttachments([]);
    setPreviews([]);

    await onSend(textToSend, filesToSend);
  };

  return (
    <div className="p-3 bg-white/5 border-t border-white/5 flex flex-col gap-2">
      {previews.length > 0 && (
        <div className="flex gap-2 overflow-x-auto no-scrollbar py-1">
          {previews.map((url, idx) => (
            <div key={idx} className="relative h-16 w-16 rounded-xl overflow-hidden border border-white/10 shrink-0">
              <img src={url} className="h-full w-full object-cover" alt="" />
              <Button 
                variant="ghost" size="icon" 
                className="absolute top-0.5 right-0.5 h-5 w-5 rounded-full bg-black/50 text-white hover:bg-red-500" 
                onClick={() => removeAttachment(idx)}
              >
                <X className="h-3 w-3" />
              </Button>
            </div>
          ))}
        </div>
      )}
      
      {editingMessage && (
        <div className="flex items-center justify-between px-3 py-1.5 bg-primary/10 rounded-xl border border-primary/20 animate-in slide-in-from-bottom-2">
          <div className="flex items-center gap-2 overflow-hidden">
            <Edit className="h-3 w-3 text-primary shrink-0" />
            <span className="text-[10px] font-bold uppercase text-primary">{t('meetingChat.editing')}</span>
          </div>
          <Button variant="ghost" size="icon" className="h-5 w-5 rounded-full" onClick={onCancelEdit}>
            <X className="h-3 w-3" />
          </Button>
        </div>
      )}

      <form onSubmit={handleSubmit} className="flex gap-2 items-end">
        <div className="flex-1 flex items-center gap-1 bg-black/40 border border-white/5 rounded-2xl p-1 focus-within:ring-1 focus-within:ring-primary/50 transition-all">
          <Button 
            type="button" 
            variant="ghost" 
            size="icon" 
            className="rounded-full h-8 w-8 shrink-0 text-white/40 hover:text-white" 
            onClick={() => fileInputRef.current?.click()} 
            disabled={isUploading}
          >
            <Paperclip className="h-4 w-4" />
          </Button>
          <input 
            type="file" 
            multiple 
            className="hidden" 
            ref={fileInputRef} 
            onChange={handleFileSelect} 
            accept="image/*" 
          />
          <Input 
            value={value} 
            onChange={(e) => onChange(e.target.value)} 
            onPaste={handlePaste}
            placeholder={t('meetingChat.placeholder')}
            className="border-none bg-transparent h-8 text-sm focus-visible:ring-0 shadow-none px-1" 
          />
        </div>
        <Button 
          type="submit" 
          size="icon" 
          className="rounded-full shrink-0 h-10 w-10 bg-primary shadow-lg shadow-primary/20 transition-all active:scale-90" 
          disabled={isUploading || (!value.trim() && attachments.length === 0)}
        >
          {isUploading ? <Loader2 className="h-4 w-4 animate-spin text-white" /> : <Send className="h-4 w-4 text-white" />}
        </Button>
      </form>
    </div>
  );
}