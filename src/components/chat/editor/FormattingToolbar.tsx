'use client';

import React from 'react';
import { type Editor } from '@tiptap/react';
import { 
  Bold, Italic, Strikethrough, Underline as UnderlineIcon, 
  EyeOff, Hash, Quote, Terminal, Link as LinkIcon, X, ArrowLeft
} from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Popover, PopoverContent, PopoverTrigger } from '@/components/ui/popover';
import { cn } from '@/lib/utils';

interface FormattingToolbarProps {
  editor: Editor | null;
  onBack: () => void;
}

export function FormattingToolbar({ editor, onBack }: FormattingToolbarProps) {
  const [linkUrl, setLinkUrl] = React.useState('');
  const [isLinkOpen, setIsLinkOpen] = React.useState(false);

  if (!editor) return null;

  const applyFormat = (command: () => void) => {
    command();
    editor.chain().focus().run();
  };

  const handleLinkSubmit = () => {
    if (!linkUrl) {
      editor.chain().focus().extendMarkRange('link').unsetLink().run();
    } else {
      const { from, to } = editor.state.selection;
      if (from === to) {
        // If nothing is selected, insert the URL text and link it
        editor.chain().focus().insertContent(linkUrl).extendMarkRange('link').setLink({ href: linkUrl }).run();
      } else {
        editor.chain().focus().extendMarkRange('link').setLink({ href: linkUrl }).run();
      }
    }
    setLinkUrl('');
    setIsLinkOpen(false);
  };

  return (
    <div className="space-y-1 animate-in slide-in-from-left-2 duration-200">
      <div className="flex items-center justify-between px-2 py-1 mb-1">
        <span className="text-[10px] font-black uppercase tracking-widest text-muted-foreground">Форматирование</span>
        <Button variant="ghost" size="icon" className="h-6 w-6 rounded-full" onClick={onBack}>
          <ArrowLeft className="h-3.5 w-3.5" />
        </Button>
      </div>
      
      <div className="grid grid-cols-4 gap-1 p-1">
        <FormatButton icon={Bold} onClick={() => applyFormat(() => editor.chain().toggleBold().run())} active={editor.isActive('bold')} />
        <FormatButton icon={Italic} onClick={() => applyFormat(() => editor.chain().toggleItalic().run())} active={editor.isActive('italic')} />
        <FormatButton icon={UnderlineIcon} onClick={() => applyFormat(() => editor.chain().toggleUnderline().run())} active={editor.isActive('underline')} />
        <FormatButton icon={Strikethrough} onClick={() => applyFormat(() => editor.chain().toggleStrike().run())} active={editor.isActive('strike')} />
        
        <Popover open={isLinkOpen} onOpenChange={setIsLinkOpen}>
          <PopoverTrigger asChild>
            <button type="button" className={cn("h-10 flex items-center justify-center rounded-xl transition-all hover:bg-white/10", editor.isActive('link') && "text-primary bg-primary/10")}>
              <LinkIcon className="h-4 w-4" />
            </button>
          </PopoverTrigger>
          <PopoverContent className="w-72 p-4 rounded-2xl shadow-2xl border-none bg-popover/90 backdrop-blur-xl mb-2" side="right">
            <div className="space-y-3">
              <h4 className="text-xs font-bold uppercase tracking-wider">Ссылка</h4>
              <Input placeholder="https://..." value={linkUrl} onChange={(e) => setLinkUrl(e.target.value)} className="h-9 rounded-xl text-xs" autoFocus onKeyDown={(e) => e.key === 'Enter' && handleLinkSubmit()} />
              <Button size="sm" onClick={handleLinkSubmit} className="w-full rounded-xl font-bold">Применить</Button>
            </div>
          </PopoverContent>
        </Popover>

        <FormatButton icon={EyeOff} onClick={() => applyFormat(() => editor.chain().toggleMark('spoiler').run())} active={editor.isActive('spoiler')} />
        <FormatButton icon={Hash} onClick={() => applyFormat(() => editor.chain().toggleCode().run())} active={editor.isActive('code')} />
        <FormatButton icon={Quote} onClick={() => applyFormat(() => editor.chain().toggleBlockquote().run())} active={editor.isActive('blockquote')} />
      </div>
    </div>
  );
}

function FormatButton({ icon: Icon, onClick, active }: any) {
  return (
    <button 
      type="button" 
      onClick={(e) => { e.stopPropagation(); onClick(); }} 
      className={cn(
        "h-10 flex items-center justify-center rounded-xl transition-all hover:bg-white/10 active:scale-90", 
        active ? "text-primary bg-primary/10" : "text-foreground/70"
      )}
    >
      <Icon className="h-4 w-4" />
    </button>
  );
}
