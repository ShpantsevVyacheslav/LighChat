'use client';

import { rgbaToThumbHash, thumbHashToDataURL } from 'thumbhash';

/**
 * Extracts width, height, and generates a ThumbHash for a given image file.
 * Returns metadata to be stored in the database for better loading experience.
 */
export async function getImageMetadata(file: File): Promise<{ width: number; height: number; thumbHash: string | null }> {
    if (!file.type.startsWith('image/')) {
        return { width: 0, height: 0, thumbHash: null };
    }

    return new Promise((resolve) => {
        const url = URL.createObjectURL(file);
        const img = new Image();
        
        img.onload = () => {
            const width = img.naturalWidth;
            const height = img.naturalHeight;
            
            // 1. Prepare small canvas for hash generation
            const canvas = document.createElement('canvas');
            const maxDim = 100;
            const scale = Math.min(maxDim / width, maxDim / height);
            canvas.width = Math.round(width * scale);
            canvas.height = Math.round(height * scale);
            
            const ctx = canvas.getContext('2d');
            if (!ctx) {
                URL.revokeObjectURL(url);
                resolve({ width, height, thumbHash: null });
                return;
            }

            // 2. Draw image to extract pixel data
            ctx.drawImage(img, 0, 0, canvas.width, canvas.height);
            const imageData = ctx.getImageData(0, 0, canvas.width, canvas.height);
            
            try {
                // 3. Generate ThumbHash
                const hash = rgbaToThumbHash(imageData.width, imageData.height, imageData.data);
                
                // 4. Convert Uint8Array to base64 string for DB storage
                const thumbHash = btoa(String.fromCharCode(...hash));
                
                URL.revokeObjectURL(url);
                resolve({ width, height, thumbHash });
            } catch (err) {
                console.warn("[MediaUtils] ThumbHash generation failed:", err);
                URL.revokeObjectURL(url);
                resolve({ width, height, thumbHash: null });
            }
        };

        img.onerror = () => {
            URL.revokeObjectURL(url);
            resolve({ width: 0, height: 0, thumbHash: null });
        };

        img.src = url;
    });
}

/**
 * Converts a ThumbHash base64 string back to a размытый Data URL for immediate display.
 */
export function thumbHashToUrl(hashStr: string | null | undefined): string | null {
    if (!hashStr) return null;
    try {
        const binary = atob(hashStr);
        const array = new Uint8Array(binary.length);
        for (let i = 0; i < binary.length; i++) {
            array[i] = binary.charCodeAt(i);
        }
        return thumbHashToDataURL(array);
    } catch (e) {
        console.warn("[MediaUtils] Decoding ThumbHash failed:", e);
        return null;
    }
}

/**
 * Добавляет media fragment `#t=0.1`, чтобы превью видео показывало кадр, а не чёрный экран
 * (как в MessageMedia). Базовый URL без существующего фрагмента.
 */
export function videoUrlWithPreviewFrame(url: string): string {
    if (!url) return url;
    const base = url.split("#")[0] ?? url;
    return `${base}#t=0.1`;
}
