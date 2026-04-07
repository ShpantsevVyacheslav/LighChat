const { app, BrowserWindow, session, ipcMain } = require('electron');
const path = require('path');

// Установка ID для корректной работы уведомлений в Windows
if (process.platform === 'win32') {
  app.setAppUserModelId("com.lighchat.app");
}

let mainWindow;

function createWindow() {
  mainWindow = new BrowserWindow({
    width: 1280,
    height: 800,
    title: "LighChat",
    webPreferences: {
      nodeIntegration: false,
      contextIsolation: true,
      preload: path.join(__dirname, 'preload.js')
    },
    backgroundColor: '#0a0e17',
    icon: path.join(__dirname, '../public/icon.png')
  });

  const isDev = !app.isPackaged;
  const remoteUrl = 'https://project-72b24.web.app';
  const startUrl = isDev ? 'http://localhost:3000' : remoteUrl;

  mainWindow.loadURL(startUrl);

  mainWindow.webContents.on('did-finish-load', () => {
    const title = mainWindow.getTitle();
    if (title === "Site Not Found" || title === "404 Not Found") {
        showDeploymentError(mainWindow);
    }
  });

  function showDeploymentError(win) {
    win.setMenu(null);
    win.loadURL(`data:text/html;charset=utf-8,
        <html>
            <body style="background-color: #0a0e17; color: white; font-family: sans-serif; display: flex; flex-direction: column; align-items: center; justify-content: center; height: 100vh; text-align: center; padding: 40px; margin: 0;">
                <h1>Веб-версия не найдена</h1>
                <p>Приложение не может загрузить интерфейс. Опубликуйте сайт в Firebase Hosting.</p>
                <button onclick="window.location.reload()">Повторить попытку</button>
            </body>
        </html>
    `);
  }

  session.defaultSession.setPermissionCheckHandler(() => true);
  session.defaultSession.setPermissionRequestHandler((wc, p, cb) => cb(true));

  mainWindow.webContents.setWindowOpenHandler(({ url }) => {
    if (url.startsWith('http')) {
      require('electron').shell.openExternal(url);
    }
    return { action: 'deny' };
  });
}

// IPC Listeners
ipcMain.on('request-focus', () => {
  if (mainWindow) {
    if (mainWindow.isMinimized()) mainWindow.restore();
    mainWindow.focus();
    mainWindow.flashFrame(true); // Flash taskbar icon
  }
});

ipcMain.on('set-badge', (event, count) => {
  if (app.setBadgeCount) {
    app.setBadgeCount(count);
  }
});

app.whenReady().then(() => {
  createWindow();
  app.on('activate', () => {
    if (BrowserWindow.getAllWindows().length === 0) createWindow();
  });
});

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') app.quit();
});
