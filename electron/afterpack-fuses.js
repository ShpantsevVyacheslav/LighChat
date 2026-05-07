// SECURITY: electron-builder afterPack hook that flips Electron Fuses on the
// built binary. Without this, an attacker who lands in the user's profile
// directory can:
//   - drop their own asar at app.asar and bypass code signing entirely
//     (we do `OnlyLoadAppFromAsar = true` to refuse loose .js / loose dirs);
//   - run the signed Electron binary as a Node interpreter via
//     `--inspect`/`--inspect-brk`/`NODE_OPTIONS` (we disable both fuses);
//   - tamper with .asar bytes (we enable embedded integrity validation).
//
// We deliberately keep `runAsNode = true` because the bundled-Next launcher
// in main.js spawns process.execPath with ELECTRON_RUN_AS_NODE = '1' to run
// the Next standalone server. Disabling it breaks startup. The remaining
// fuses still meaningfully harden the binary against code-injection attacks.
//
// This file is no-op when @electron/fuses isn't installed (CI without
// devDependencies, dev environments without packaging) — the build keeps
// going so contributors don't get blocked. Installing it is gated behind
// `npm install` of @electron/fuses (added to package.json devDeps).

/* eslint-disable @typescript-eslint/no-require-imports */
const path = require('node:path');

module.exports = async function afterPackFuses(context) {
  let flipFuses;
  let FuseVersion;
  let FuseV1Options;
  try {
    const fuses = require('@electron/fuses');
    flipFuses = fuses.flipFuses;
    FuseVersion = fuses.FuseVersion;
    FuseV1Options = fuses.FuseV1Options;
  } catch (e) {
    console.warn('[afterPack-fuses] @electron/fuses not installed; skipping. ' +
      'Run `npm install` to enable production fuse hardening.');
    return;
  }

  const { electronPlatformName, appOutDir, packager } = context;
  const productName = packager.appInfo.productFilename;
  const exeName =
    electronPlatformName === 'darwin' ? `${productName}.app`
      : electronPlatformName === 'win32' ? `${productName}.exe`
        : productName;
  const electronBinary = path.join(appOutDir, exeName);

  console.log('[afterPack-fuses] flipping fuses on', electronBinary);
  await flipFuses(electronBinary, {
    version: FuseVersion.V1,
    resetAdHocDarwinSignature: electronPlatformName === 'darwin',
    // Keep RunAsNode TRUE — main.js relies on ELECTRON_RUN_AS_NODE for the
    // bundled Next standalone server. See notes at top of file.
    [FuseV1Options.RunAsNode]: true,
    // Disable the cookie-encryption-via-os-crypt downgrade path on Linux —
    // ensures stored cookies (Firebase Auth refresh tokens via IndexedDB)
    // use the OS keystore where available.
    [FuseV1Options.EnableCookieEncryption]: true,
    // Reject NODE_OPTIONS / --inspect / --inspect-brk on the production
    // binary. Otherwise an attacker with execve access (or social
    // engineering) gets a Node REPL inside our signed app context.
    [FuseV1Options.EnableNodeOptionsEnvironmentVariable]: false,
    [FuseV1Options.EnableNodeCliInspectArguments]: false,
    // Validate embedded asar integrity — the asar header stores SHA256s
    // against which the runtime checks file reads. Combined with
    // OnlyLoadAppFromAsar this means a tampered asar refuses to launch.
    [FuseV1Options.EnableEmbeddedAsarIntegrityValidation]: true,
    [FuseV1Options.OnlyLoadAppFromAsar]: true,
    // Strip out the legacy "load loose JS" code path entirely.
    [FuseV1Options.LoadBrowserProcessSpecificV8Snapshot]: false,
    [FuseV1Options.GrantFileProtocolExtraPrivileges]: false,
  });
  console.log('[afterPack-fuses] done');
};
