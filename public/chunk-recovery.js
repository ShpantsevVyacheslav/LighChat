// SECURITY: external script (no inline, CSP-friendly). Originally lived as
// dangerouslySetInnerHTML inside layout.tsx which forced us to keep
// 'unsafe-inline' (or to manage a per-request nonce just for this one
// recovery handler). Self-hosted at /chunk-recovery.js, eligible under
// `script-src 'self'` with the rest of our scripts.
//
// Behaviour: when the browser hits a stale Next.js bundle (typical right
// after a deploy when /_next/static/chunks/<hash>.js no longer exists), the
// load failure surfaces as a 'ChunkLoadError' / 'Loading chunk … failed'.
// We reload once to fetch the current bundle. We deliberately do NOT loop —
// if the reload hits the same error a second time it's a real bug, and we
// want it visible in the console / error tracking.
(function () {
  var reloaded = false;
  window.addEventListener('error', function (event) {
    if (reloaded) return;
    var msg = event && event.message ? String(event.message) : '';
    if (msg.indexOf('ChunkLoadError') !== -1 || msg.indexOf('Loading chunk') !== -1) {
      reloaded = true;
      window.location.reload();
    }
  });
})();
