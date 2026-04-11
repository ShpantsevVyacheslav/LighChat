const { contextBridge, ipcRenderer } = require('electron');
const { CHANNEL_GET_CACHED_MEDIA_URL } = require('./media-cache');

contextBridge.exposeInMainWorld('electronAPI', {
  requestFocus: () => ipcRenderer.send('request-focus'),
  setBadge: (count) => ipcRenderer.send('set-badge', count),
  getCachedMediaUrl: (remoteUrl) => ipcRenderer.invoke(CHANNEL_GET_CACHED_MEDIA_URL, remoteUrl),
});