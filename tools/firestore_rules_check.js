/* eslint-disable no-console */
/**
 * Minimal Firestore Rules check harness.
 *
 * Usage:
 *   node tools/firestore_rules_check.js
 *
 * Requires:
 *   - `firebase emulators:start --only firestore` running (default ports)
 */

const fs = require("node:fs");
const path = require("node:path");

const {
  assertSucceeds,
  assertFails,
  initializeTestEnvironment,
} = require("@firebase/rules-unit-testing");

const PROJECT_ID = "project-72b24";
const FIRESTORE_EMULATOR_HOST = "127.0.0.1";
const FIRESTORE_EMULATOR_PORT = 8080;

const UID = "5edHRxyQKWZEk4M2iQ3lBjDKKdd2";
const CONVERSATION_ID =
  "dm_28:5edHRxyQKWZEk4M2iQ3lBjDKKdd2_28:UyhfMen0NITWtlazwjlk8ZTJ2gv1";
const SECRET_NO_LOCK_ID =
  "sdm_28:5edHRxyQKWZEk4M2iQ3lBjDKKdd2_28:UyhfMen0NITWtlazwjlk8ZTJ2gv1";
const SECRET_WITH_LOCK_ID =
  "sdm_28:5edHRxyQKWZEk4M2iQ3lBjDKKdd2_28:zzzzzzzzzzzzzzzzzzzzzzzzzzzz";
const SECRET_WITH_LOCK_NO_GRANT_ID =
  "sdm_28:5edHRxyQKWZEk4M2iQ3lBjDKKdd2_28:yyyyyyyyyyyyyyyyyyyyyyyyyyyy";

async function main() {
  const rulesPath = path.join(process.cwd(), "firestore.rules");
  const rules = fs.readFileSync(rulesPath, "utf8");

  const testEnv = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: {
      host: FIRESTORE_EMULATOR_HOST,
      port: FIRESTORE_EMULATOR_PORT,
      rules,
    },
  });

  // Seed minimal data under disabled rules.
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    await db.doc(`conversations/${CONVERSATION_ID}`).set({
      isGroup: false,
      adminIds: [],
      participantIds: [UID, "UyhfMen0NITWtlazwjlk8ZTJ2gv1"],
      participantInfo: {
        [UID]: { name: "Tester" },
        UyhfMen0NITWtlazwjlk8ZTJ2gv1: { name: "Partner" },
      },
    });
    await db.doc(`conversations/${CONVERSATION_ID}/members/${UID}`).set({
      userId: UID,
    });
    await db
      .collection(`conversations/${CONVERSATION_ID}/messages`)
      .doc("m1")
      .set({
        senderId: UID,
        createdAt: new Date().toISOString(),
        text: "hi",
      });

    await db.doc(`conversations/${SECRET_NO_LOCK_ID}`).set({
      isGroup: false,
      adminIds: [],
      participantIds: [UID, "UyhfMen0NITWtlazwjlk8ZTJ2gv1"],
      secretChat: {
        enabled: true,
        lockPolicy: { required: false },
      },
    });
    await db
      .collection(`conversations/${SECRET_NO_LOCK_ID}/messages`)
      .doc("m1")
      .set({
        senderId: UID,
        createdAt: new Date().toISOString(),
        text: "secret-unlocked-by-default",
      });

    await db.doc(`conversations/${SECRET_WITH_LOCK_ID}`).set({
      isGroup: false,
      adminIds: [],
      participantIds: [UID, "zzzzzzzzzzzzzzzzzzzzzzzzzzzz"],
      secretChat: {
        enabled: true,
        lockPolicy: { required: true },
      },
    });
    await db
      .collection(`conversations/${SECRET_WITH_LOCK_ID}/messages`)
      .doc("m1")
      .set({
        senderId: UID,
        createdAt: new Date().toISOString(),
        text: "secret-locked",
      });
    await db
      .doc(`conversations/${SECRET_WITH_LOCK_ID}/secretAccess/${UID}`)
      .set({
        userId: UID,
        expiresAtTs: new Date(Date.now() + 10 * 60 * 1000),
      });

    await db.doc(`conversations/${SECRET_WITH_LOCK_NO_GRANT_ID}`).set({
      isGroup: false,
      adminIds: [],
      participantIds: [UID, "yyyyyyyyyyyyyyyyyyyyyyyyyyyy"],
      secretChat: {
        enabled: true,
        lockPolicy: { required: true },
      },
    });
    await db
      .collection(`conversations/${SECRET_WITH_LOCK_NO_GRANT_ID}/messages`)
      .doc("m1")
      .set({
        senderId: UID,
        createdAt: new Date().toISOString(),
        text: "secret-locked-no-grant",
      });
  });

  const authed = testEnv.authenticatedContext(UID);
  const db = authed.firestore();

  const checks = [
    {
      name: "get conversation doc",
      run: () => db.doc(`conversations/${CONVERSATION_ID}`).get(),
      expect: "succeeds",
    },
    {
      name: "get member doc",
      run: () => db.doc(`conversations/${CONVERSATION_ID}/members/${UID}`).get(),
      expect: "succeeds",
    },
    {
      name: "list messages",
      run: () => db.collection(`conversations/${CONVERSATION_ID}/messages`).limit(1).get(),
      expect: "succeeds",
    },
    {
      name: "list e2eeSessions",
      run: () => db.collection(`conversations/${CONVERSATION_ID}/e2eeSessions`).limit(1).get(),
      expect: "succeeds",
    },
    {
      name: "list gameLobbies",
      run: () => db.collection(`conversations/${CONVERSATION_ID}/gameLobbies`).limit(1).get(),
      expect: "succeeds",
    },
    {
      name: "list messages in secret chat without lockPolicy.required",
      run: () => db.collection(`conversations/${SECRET_NO_LOCK_ID}/messages`).limit(1).get(),
      expect: "succeeds",
    },
    {
      name: "list messages in secret chat with lockPolicy.required and active grant",
      run: () => db.collection(`conversations/${SECRET_WITH_LOCK_ID}/messages`).limit(1).get(),
      expect: "succeeds",
    },
    {
      name: "deny messages read in secret chat with lockPolicy.required and no grant",
      run: () => db.collection(`conversations/${SECRET_WITH_LOCK_NO_GRANT_ID}/messages`).limit(1).get(),
      expect: "fails",
    },
  ];

  for (const c of checks) {
    try {
      if (c.expect === "succeeds") {
        await assertSucceeds(c.run());
      } else {
        await assertFails(c.run());
      }
      console.log(`OK: ${c.name}`);
    } catch (e) {
      console.error(`FAIL: ${c.name}`);
      console.error(e);
    }
  }

  await testEnv.cleanup();
}

main().catch((e) => {
  console.error("Unhandled error:", e);
  process.exitCode = 1;
});

