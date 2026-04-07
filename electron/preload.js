const { contextBridge, ipcRenderer } = require('electron');

contextBridge.exposeInMainWorld('electronAPI', {
  requestFocus: () => ipcRenderer.send('request-focus'),
  setBadge: (count) => ipcRenderer.send('set-badge', count)
});