# PWA Push FCM Key Migration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Restore reliable web push subscription in desktop and iOS Home Screen PWA by migrating to the new API key and hardening notification preflight checks.

**Architecture:** Update web Firebase config to the new browser API key, keep SW/FCM flow unchanged, and add explicit capability guards before requesting notification permission. Improve error mapping for unsupported contexts to avoid ambiguous failures. Verify the full Firebase surface (auth/firestore/storage/push) after migration.

**Tech Stack:** Next.js 14, React 18, TypeScript, Firebase Web SDK (messaging), Google Cloud API key restrictions.

---

## File Structure

- Modify: `src/firebase/config.ts`
  - Switch web `apiKey` to the newly created browser key.
- Modify: `src/hooks/use-notifications.ts`
  - Add `Notification` API preflight guard before `requestPermission()`.
- Modify: `src/lib/fcm-subscribe-user-message.ts`
  - Map unsupported notification context errors to user-friendly text.
- Modify: `docs/troubleshooting-fcm-web.md`
  - Add migration checklist and verification flow.
- Modify: `docs/arcitecture/05-integrations.md`
  - Sync architecture docs for FCM/PWA constraints.

### Task 1: Migrate Firebase web API key

**Files:**
- Modify: `src/firebase/config.ts`

- [ ] **Step 1: Replace `apiKey` with the new key value**

```ts
// src/firebase/config.ts
export const firebaseConfig = {
  apiKey: 'AIzaSyD9GMaIREDiU4twHnMQg5utITpJ7ZVnlYE',
  authDomain: 'project-72b24.firebaseapp.com',
  projectId: 'project-72b24',
  storageBucket: 'project-72b24.firebasestorage.app',
  messagingSenderId: '262148817877',
  appId: '1:262148817877:web:d4191fc34eca6977f0335c',
};
```

- [ ] **Step 2: Run typecheck**

Run: `npm run typecheck`
Expected: PASS

- [ ] **Step 3: Commit key migration**

```bash
git add src/firebase/config.ts
git commit -m "chore: migrate web firebase api key for push stability"
```

### Task 2: Add notification API preflight guard

**Files:**
- Modify: `src/hooks/use-notifications.ts`

- [ ] **Step 1: Guard unsupported notification context before permission request**

```ts
if (typeof window === 'undefined' || typeof Notification === 'undefined') {
  throw new Error(
    'Push в этом окне недоступен. На iPhone откройте установленное приложение с экрана «Домой».',
  );
}

const currentPermission = await Notification.requestPermission();
```

- [ ] **Step 2: Keep current fallback flow and normalize thrown errors through mapper**

```ts
} catch (err) {
  console.error('Error subscribing to notifications: ', err);
  const message = fcmSubscribeUserMessage(err);
  setError(message);
  ...
}
```

- [ ] **Step 3: Run typecheck**

Run: `npm run typecheck`
Expected: PASS

- [ ] **Step 4: Commit guard improvement**

```bash
git add src/hooks/use-notifications.ts
git commit -m "fix: guard notification api before fcm permission request"
```

### Task 3: Improve FCM subscribe error text mapping

**Files:**
- Modify: `src/lib/fcm-subscribe-user-message.ts`

- [ ] **Step 1: Add mapping for unsupported notification API context**

```ts
if (/Can't find variable: Notification|Notification is not defined/i.test(raw)) {
  return (
    'Push в этом окне недоступен. На iPhone откройте установленное приложение с экрана «Домой». '
    + 'В обычной вкладке Safari web-push может быть недоступен.'
  );
}
```

- [ ] **Step 2: Keep existing credential-hint branch unchanged**

```ts
if (credentialHint || (code === 'messaging/token-subscribe-failed' && /credential|OAuth|UNAUTHENTICATED/i.test(raw))) {
  return 'FCM: Google отклонил запрос ...';
}
```

- [ ] **Step 3: Run typecheck**

Run: `npm run typecheck`
Expected: PASS

- [ ] **Step 4: Commit mapper update**

```bash
git add src/lib/fcm-subscribe-user-message.ts
git commit -m "fix: improve fcm subscription error messages for unsupported contexts"
```

### Task 4: Sync docs and validate end-to-end

**Files:**
- Modify: `docs/troubleshooting-fcm-web.md`
- Modify: `docs/arcitecture/05-integrations.md`

- [ ] **Step 1: Update troubleshooting doc with key migration checklist**

```md
- Use dedicated/new browser API key for web app config (`src/firebase/config.ts`).
- Keep old key until smoke tests pass.
- Verify desktop + iOS Home Screen PWA separately.
```

- [ ] **Step 2: Update integrations doc for PWA push constraints**

```md
- FCM web push requires browser API key policy and iOS standalone PWA context.
- Safari tab may not expose Notification API; subscription must be done from installed Home Screen app.
```

- [ ] **Step 3: Execute manual smoke verification**

```text
1) Desktop: login, chats, storage upload, enable notifications.
2) iOS Safari tab: shows clear unsupported-context error.
3) iOS Home Screen PWA: enable notifications succeeds.
4) Send message from another account: push arrives in background.
```

- [ ] **Step 4: Commit docs sync**

```bash
git add docs/troubleshooting-fcm-web.md docs/arcitecture/05-integrations.md
git commit -m "docs: document fcm key migration and pwa push context requirements"
```
