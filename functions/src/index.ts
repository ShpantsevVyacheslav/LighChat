// This file is the entry point for all Cloud Functions.
// It imports and re-exports all functions from their individual files.

import * as admin from "firebase-admin";

// Initialize Firebase Admin SDK
if (admin.apps.length === 0) {
  admin.initializeApp();
}

// --- EXPORT TRIGGERS ---

// Auth Triggers
export { onUserCreated } from './triggers/auth/onUserCreated';

// HTTP Triggers (onCall)
export { createNewUser } from './triggers/http/createNewUser';
export { signInWithTelegram } from './triggers/http/signInWithTelegram';
export { updateUserAdmin } from './triggers/http/updateUserAdmin';
export { backfillConversationMembers } from './triggers/http/backfillConversationMembers';
export { backfillOutgoingBlocks } from './triggers/http/backfillOutgoingBlocks';
export { backfillRegistrationIndex } from './triggers/http/backfillRegistrationIndex';
export { requestMeetingAccess, respondToMeetingRequest } from './triggers/http/meetingJoinRequests';
export { checkGroupInvitesAllowed } from './triggers/http/checkGroupInvitesAllowed';
export { retryChatMediaTranscode } from './triggers/http/retryChatMediaTranscode';
export { deleteAccount } from './triggers/http/deleteAccount';
export { transcribeVoiceMessage } from './triggers/http/transcribeVoiceMessage';
export { setSecretChatPin } from './triggers/http/setSecretChatPin';
export { unlockSecretChat } from './triggers/http/unlockSecretChat';
export { updateSecretChatSettings } from './triggers/http/updateSecretChatSettings';
export { migrateSecretChatIndexes } from './triggers/http/migrateSecretChatIndexes';
export { deleteSecretChat } from './triggers/http/deleteSecretChat';
export { verifySecretVaultPin } from './triggers/http/verifySecretVaultPin';
export { hasSecretVaultPin } from './triggers/http/hasSecretVaultPin';
export { requestSecretMediaView } from './triggers/http/requestSecretMediaView';
export { fulfillSecretMediaViewRequest } from './triggers/http/fulfillSecretMediaViewRequest';
export { consumeSecretMediaKeyGrant } from './triggers/http/consumeSecretMediaKeyGrant';
export { createGameLobby } from './triggers/http/createGameLobby';
export { joinGameLobby } from './triggers/http/joinGameLobby';
export { startDurakGame } from './triggers/http/startDurakGame';
export { makeDurakMove } from './triggers/http/makeDurakMove';
export { cancelGameLobby } from './triggers/http/cancelGameLobby';
export { createDurakTournament } from './triggers/http/createDurakTournament';
export { createTournamentGameLobby } from './triggers/http/createTournamentGameLobby';

// Firestore Triggers
export { onconversationcreated } from './triggers/firestore/onConversationCreated';
export { onuserwritesyncregistrationindex } from './triggers/firestore/onUserWriteSyncRegistrationIndex';
export { onuserwriteblocksideeffects } from './triggers/firestore/onUserWriteBlockSideEffects';
export { onconversationdeleted } from './triggers/firestore/onConversationDeleted';
export { onconversationupdated } from './triggers/firestore/onConversationUpdated';
export { onmessagecreated } from './triggers/firestore/onMessageCreated';
export { onthreadmessagecreated } from './triggers/firestore/onThreadMessageCreated';
export { onchatmessagedeleted, onchatthreadmessagedeleted } from './triggers/firestore/onChatMessageDeleted';
export {
  onchatmessagemediatranscode,
  onchatthreadmessagemediatranscode,
} from './triggers/firestore/onChatMessageMediaTranscode';
export { oncallcreated } from './triggers/firestore/onCallCreated';
export { onmeetingparticipantcreated } from './triggers/firestore/onMeetingParticipantCreated';

// Scheduler Triggers
export { checkUserPresence } from './triggers/scheduler/checkUserPresence';
// Phase 6: TTL-cleanup эфемерных QR-pairing сессий E2EE v2.
export { cleanupE2eePairingSessions } from './triggers/scheduler/cleanupE2eePairingSessions';
export { cleanupExpiredSecretChats } from './triggers/scheduler/cleanupExpiredSecretChats';
export { cleanupSecretMediaRequests } from './triggers/scheduler/cleanupSecretMediaRequests';
