const { app, BrowserWindow, session, ipcMain } = require('electron');
const path = require('path');
const fs = require('fs');
const { spawn } = require('child_process');

require('./media-cache');

/** В терминале: `LIGHCHAT_ELECTRON_DEBUG=1 /Applications/LighChat.app/Contents/MacOS/LighChat` — DevTools + лог Next в userData. */
function isElectronDebug() {
  const v = process.env.LIGHCHAT_ELECTRON_DEBUG;
  return v === '1' || v === 'true';
}

// Установка ID для корректной работы уведомлений в Windows
if (process.platform === 'win32') {
  app.setAppUserModelId("com.lighchat.app");
}

let mainWindow;
let localNextServerProcess = null;

function createWindow() {
  if (mainWindow && !mainWindow.isDestroyed()) {
    mainWindow.focus();
    return;
  }

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
    icon: path.join(__dirname, '../public/icon.png'),
    show: false,
  });

  const isDev = !app.isPackaged;
  const startUrl = isDev ? 'http://localhost:3000' : null;

  const finishShowWindow = () => {
    if (!mainWindow || mainWindow.isDestroyed()) return;
    mainWindow.show();
    if (isElectronDebug()) {
      mainWindow.webContents.openDevTools({ mode: 'detach' });
    }
  };

  if (startUrl) {
    mainWindow.loadURL(startUrl).then(finishShowWindow).catch(finishShowWindow);
  } else {
    startLocalNextServer()
      .then((url) => mainWindow.loadURL(url))
      .then(finishShowWindow)
      .catch((err) => {
        console.error('[Electron] Failed to start embedded Next or load page.', err);
        try {
          showDeploymentError(mainWindow, String(err?.message || err));
        } catch (e) {
          /* ignore */
        }
        finishShowWindow();
      });
  }

  mainWindow.webContents.on(
    'did-fail-load',
    (_event, errorCode, errorDescription, validatedURL, isMainFrame) => {
      if (!mainWindow) return;
      /** Только документ вкладки; подресурсы и старые Electron без флага не гасим целиком UI. */
      if (isMainFrame === false) return;
      // Частый шум при отмене/перенаправлениях — не подменяем весь UI.
      if (errorCode === -3 /* ERR_ABORTED */) return;
      console.error('[Electron] did-fail-load (main frame)', { errorCode, errorDescription, validatedURL });
      showDeploymentError(
        mainWindow,
        `Ошибка загрузки страницы (${errorCode}): ${errorDescription}\n${validatedURL || ''}`
      );
    }
  );

  mainWindow.webContents.on('did-finish-load', () => {
    const title = mainWindow.getTitle();
    if (title === "Site Not Found" || title === "404 Not Found") {
        showDeploymentError(mainWindow, 'Страница вернула 404.');
    }
  });

  mainWindow.webContents.on('render-process-gone', (_event, details) => {
    console.error('[Electron] render-process-gone', details);
  });

  if (isElectronDebug()) {
    const logPath = path.join(app.getPath('userData'), 'electron-debug.log');
    console.info('[Electron] LIGHCHAT_ELECTRON_DEBUG: логи рендера →', logPath);
    const appendLog = (chunk) => {
      try {
        fs.appendFileSync(logPath, String(chunk));
      } catch (e) {
        console.warn('[Electron] appendLog failed', e);
      }
    };
    fs.appendFileSync(logPath, `\n--- session ${new Date().toISOString()} pid=${process.pid} ---\n`);
    mainWindow.webContents.on('console-message', (_e, level, message, line, sourceId) => {
      appendLog(`[console L${level}] ${message} (${sourceId}:${line})\n`);
    });
  }

  function showDeploymentError(win, details) {
    win.setMenu(null);
    win.loadURL(`data:text/html;charset=utf-8,
        <html>
            <body style="background-color: #0a0e17; color: white; font-family: sans-serif; display: flex; flex-direction: column; align-items: center; justify-content: center; height: 100vh; text-align: center; padding: 40px; margin: 0;">
                <h1>Не удалось запустить интерфейс</h1>
                <p>Desktop-сборка должна запускать локальный Next-сервер. Проверьте содержимое сборки и логи.</p>
                <pre style="max-width: 900px; white-space: pre-wrap; background: rgba(255,255,255,0.06); border: 1px solid rgba(255,255,255,0.12); padding: 12px; border-radius: 12px; margin-top: 16px;">${escapeHtml(details || '')}</pre>
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

  mainWindow.on('closed', () => {
    mainWindow = null;
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

function escapeHtml(s) {
  return String(s)
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&#039;');
}

async function waitForHttpOk(url, { timeoutMs = 15000 } = {}) {
  const deadline = Date.now() + timeoutMs;
  // Lazy-require to keep top-level minimal.
  const http = require('http');

  return new Promise((resolve, reject) => {
    const tick = () => {
      if (Date.now() > deadline) {
        reject(new Error(`Timeout waiting for local server: ${url}`));
        return;
      }
      const req = http.get(url, (res) => {
        res.resume();
        if ((res.statusCode || 0) >= 200 && (res.statusCode || 0) < 500) resolve(true);
        else setTimeout(tick, 250);
      });
      req.on('error', () => setTimeout(tick, 250));
    };
    tick();
  });
}

/**
 * В production electron-builder кладёт `.next/standalone` в `app.asar.unpacked` (asarUnpack),
 * а `app.getAppPath()` указывает на `…/app.asar`. Без этого пути дочерний процесс Next не находит `server.js`.
 */
function resolveBundledStandaloneRoot() {
  if (!app.isPackaged) {
    return path.join(__dirname, '..', '.next-desktop', 'standalone');
  }

  const appPath = app.getAppPath();
  const unpackedRoot = appPath.replace(/app\.asar$/i, 'app.asar.unpacked');
  const candidates = [
    path.join(unpackedRoot, '.next-desktop', 'standalone'),
    path.join(appPath, '.next-desktop', 'standalone'),
    path.join(process.resourcesPath || '', 'app.asar.unpacked', '.next-desktop', 'standalone'),
    path.join(unpackedRoot, '.next', 'standalone'),
    path.join(appPath, '.next', 'standalone'),
  ];

  for (const dir of candidates) {
    if (fs.existsSync(path.join(dir, 'server.js'))) {
      return dir;
    }
  }

  const fallback = candidates[0];
  console.error('[Electron] server.js not found in candidates.', { candidates });
  return fallback;
}

function resolveNodePathForNext(standaloneRoot) {
  const appPath = app.getAppPath();
  const unpackedRoot = appPath.replace(/app\.asar$/i, 'app.asar.unpacked');
  const candidates = [
    path.join(standaloneRoot, 'node_modules'),
    path.join(appPath, 'node_modules'),
    path.join(unpackedRoot, 'node_modules'),
    path.join(process.resourcesPath || '', 'app.asar', 'node_modules'),
    path.join(process.resourcesPath || '', 'app.asar.unpacked', 'node_modules'),
  ];

  const existing = candidates.filter((dir, index) => {
    if (candidates.indexOf(dir) !== index) return false;
    return fs.existsSync(dir);
  });

  return existing.join(path.delimiter);
}

async function startLocalNextServer() {
  if (localNextServerProcess) {
    return 'http://127.0.0.1:3434';
  }

  const port = 3434;
  const hostname = '127.0.0.1';
  const standaloneRoot = resolveBundledStandaloneRoot();
  const serverScriptPath = path.join(standaloneRoot, 'server.js');
  const standaloneNodeModulesPath = path.join(standaloneRoot, 'node_modules');
  const resolvedNodePath = resolveNodePathForNext(standaloneRoot);

  if (!fs.existsSync(serverScriptPath)) {
    throw new Error(
      `Не найден bundled Next server: ${serverScriptPath}. Проверьте asarUnpack и наличие .next/standalone в сборке.`
    );
  }

  if (!fs.existsSync(standaloneNodeModulesPath)) {
    console.warn('[Electron] Standalone node_modules is missing, using NODE_PATH fallback.', {
      standaloneNodeModulesPath,
      resolvedNodePath,
    });
  }

  console.log('[Electron] Starting bundled Next server.', { serverScriptPath, standaloneRoot, port, hostname });

  localNextServerProcess = spawn(process.execPath, [serverScriptPath], {
    cwd: standaloneRoot,
    env: {
      ...process.env,
      /** Запуск `server.js` тем же бинарником, что и Electron, в режиме Node (без GUI). */
      ELECTRON_RUN_AS_NODE: '1',
      NODE_ENV: 'production',
      NODE_PATH: [process.env.NODE_PATH, resolvedNodePath].filter(Boolean).join(path.delimiter),
      PORT: String(port),
      HOSTNAME: hostname,
      NEXT_TELEMETRY_DISABLED: '1',
    },
    stdio: 'pipe',
  });

  const nextLogPath = isElectronDebug()
    ? path.join(app.getPath('userData'), 'next-embedded.log')
    : null;
  if (nextLogPath) {
    try {
      fs.appendFileSync(nextLogPath, `\n--- next ${new Date().toISOString()} ---\n`);
      console.info('[Electron] stdout/stderr встроенного Next →', nextLogPath);
    } catch (e) {
      /* ignore */
    }
  }

  localNextServerProcess.stdout.on('data', (d) => {
    const s = String(d).trimEnd();
    console.log(`[Next] ${s}`);
    if (nextLogPath) {
      try {
        fs.appendFileSync(nextLogPath, s + '\n');
      } catch (e) {
        /* ignore */
      }
    }
  });
  localNextServerProcess.stderr.on('data', (d) => {
    const s = String(d).trimEnd();
    console.error(`[Next] ${s}`);
    if (nextLogPath) {
      try {
        fs.appendFileSync(nextLogPath, s + '\n');
      } catch (e) {
        /* ignore */
      }
    }
  });
  localNextServerProcess.on('exit', (code) => {
    console.warn('[Electron] Bundled Next server exited.', { code });
    localNextServerProcess = null;
  });

  const url = `http://${hostname}:${port}`;
  await waitForHttpOk(url);
  return url;
}

app.whenReady().then(() => {
  createWindow();
  app.on('activate', () => {
    if (BrowserWindow.getAllWindows().length === 0) createWindow();
  });
});

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') app.quit();
});

app.on('before-quit', () => {
  try {
    if (localNextServerProcess) {
      localNextServerProcess.kill();
      localNextServerProcess = null;
    }
  } catch (e) {
    console.warn('[Electron] Failed to stop bundled Next server.', e);
  }
});
