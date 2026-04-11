const { contextBridge, ipcRenderer } = require('electron');

/** Дублируем channel-id, чтобы preload не тянул локальные модули в sandbox-режиме. */
const CHANNEL_GET_CACHED_MEDIA_URL = 'media-cache:getCachedMediaUrl';

contextBridge.exposeInMainWorld('electronAPI', {
  requestFocus: () => ipcRenderer.send('request-focus'),
  setBadge: (count) => ipcRenderer.send('set-badge', count),
  getCachedMediaUrl: (remoteUrl) => ipcRenderer.invoke(CHANNEL_GET_CACHED_MEDIA_URL, remoteUrl),
});
