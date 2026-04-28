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

