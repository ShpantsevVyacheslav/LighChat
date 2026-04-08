'use client';

import React, { useEffect, useState } from 'react';
import { getLinkMetadata } from '@/actions/link-preview-actions';
import { Skeleton } from '@/components/ui/skeleton';
import { ExternalLink } from 'lucide-react';
import { cn } from '@/lib/utils';

interface Metadata {
  title?: string | null;
  description?: string | null;
  image?: string | null;
  siteName?: string | null;
  url: string;
}

interface LinkPreviewProps {
    url: string;
    isLive?: boolean;
}

const previewCache = new Map<string, Metadata>();

export function LinkPreview({ url, isLive = false }: LinkPreviewProps) {
  const [metadata, setMetadata] = useState<Metadata | null>(previewCache.get(url) || null);
  const [loading, setLoading] = useState(!previewCache.get(url));

  useEffect(() => {
    if (previewCache.has(url)) {
        setLoading(false);
        return;
    }

    let isMounted = true;
    setLoading(true);
    
    getLinkMetadata(url).then((data) => {
      if (isMounted) {
        const result = data as Metadata | null;
        if (result && (result.title || result.description)) {
            previewCache.set(url, result);
        }
        setMetadata(result);
        setLoading(false);
      }
    });
    
    return () => { isMounted = false; };
  }, [url]);

  // Rigid container height to prevent layout shifts - matching skeleton and final view
  const containerBaseClass = cn(
    "max-w-sm my-1 overflow-hidden h-[80px] min-h-[80px] flex items-center shrink-0 w-full transition-all duration-300 border border-black/5 dark:border-white/10 rounded-xl",
    isLive ? "max-w-full bg-muted/5 border-dashed" : "bg-muted/10"
  );

  if (loading) {
    return (
      <div className={containerBaseClass}>
        <div className="h-[40px] w-[40px] shrink-0 border-r border-black/5 dark:border-white/5 overflow-hidden">
            <Skeleton className="h-full w-full rounded-none opacity-20" />
        </div>
        <div className="flex-1 flex flex-col justify-center gap-2 p-3 min-w-0 overflow-hidden">
            <Skeleton className="h-3 w-3/4 rounded-full opacity-30" />
            <Skeleton className="h-2 w-1/2 rounded-full opacity-20" />
        </div>
      </div>
    );
  }

  if (!metadata || (!metadata.title && !metadata.description)) {
    return null;
  }

  return (
    <a href={url} target="_blank" rel="noopener noreferrer" className={cn("block my-1 group/link shrink-0", isLive ? "w-full" : "max-w-sm")}>
      <div className={containerBaseClass}>
          {metadata.image && (
            <div className="h-[40px] w-[40px] overflow-hidden bg-muted shrink-0 border-r border-black/5 dark:border-white/5">
              <img
                src={metadata.image}
                alt=""
                className="object-cover w-full h-full transition-transform group-hover/link:scale-105 duration-500"
                onError={(e) => { e.currentTarget.style.display = 'none'; }}
              />
            </div>
          )}
          <div className="flex-1 min-w-0 p-3 flex flex-col justify-center overflow-hidden h-full">
            {metadata.siteName && (
              <p className="text-[8px] font-black text-primary uppercase tracking-[0.2em] leading-none mb-1 truncate">{metadata.siteName}</p>
            )}
            <p className="font-bold text-xs line-clamp-1 leading-tight group-hover/link:text-primary transition-colors">{metadata.title}</p>
            {metadata.description && (
              <p className="text-[10px] text-muted-foreground line-clamp-1 leading-relaxed mt-0.5">{metadata.description}</p>
            )}
            <div className="flex items-center gap-1 mt-1 opacity-30">
                <p className="text-[8px] font-mono truncate uppercase tracking-tighter">{new URL(url).hostname}</p>
                <ExternalLink className="h-2 w-2" />
            </div>
          </div>
      </div>
    </a>
  );
}
