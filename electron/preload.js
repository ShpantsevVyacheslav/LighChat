const { contextBridge, ipcRenderer } = require('electron');

/** Дублируем channel-id, чтобы preload не тянул локальные модули в sandbox-режиме. */
const CHANNEL_GET_CACHED_MEDIA_URL = 'media-cache:getCachedMediaUrl';

contextBridge.exposeInMainWorld('electronAPI', {
  requestFocus: () => ipcRenderer.send('request-focus'),
  setBadge: (count) => ipcRenderer.send('set-badge', count),
  getCachedMediaUrl: (remoteUrl) => ipcRenderer.invoke(CHANNEL_GET_CACHED_MEDIA_URL, remoteUrl),
  // SECURITY: opt-in OS-keystore encryption for renderer-managed secrets.
  // Returns base64 ciphertext (or null on failure) — store in IDB safely,
  // pass back to safeStorageDecrypt to recover the plaintext. Available only
  // on the main window's main frame.
  safeStorageEncrypt: (plaintext) => ipcRenderer.invoke('safe-storage:encrypt', plaintext),
  safeStorageDecrypt: (blobB64) => ipcRenderer.invoke('safe-storage:decrypt', blobB64),
});
