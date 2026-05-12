
import { onDocumentCreated } from "firebase-functions/v2/firestore";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";

import { recordAnalyticsEvent } from "../../analytics/recordEvent";
import { AnalyticsEvents } from "../../analytics/events";

const db = admin.firestore();

/**
 * Cloud Function that triggers when a new participant is added to a meeting.
 * It updates the user's meeting history index.
 */
export const onmeetingparticipantcreated = onDocumentCreated(
  "meetings/{meetingId}/participants/{participantId}",
  async (event) => {
    const participantId = event.params.participantId;
    const meetingId = event.params.meetingId;
    const data = event.data?.data() ?? {};

    const userMeetingsIndexRef = db.doc(`userMeetings/${participantId}`);

    // Add the meeting ID to the user's history index.
    // Using arrayUnion ensures no duplicates.
    try {
      await userMeetingsIndexRef.set(
        {
          meetingIds: admin.firestore.FieldValue.arrayUnion(meetingId),
        },
        { merge: true }
      );
    } catch (error) {
      console.error(`Error updating meeting history for user ${participantId}:`, error);
    }

    // Analytics: meeting_joined + meeting_guest_joined (если role='guest').
    try {
      const role = typeof data.role === "string" ? data.role : "guest";
      const isGuest = role === "guest";
      const joinMethod =
        typeof data.joinMethod === "string" ? data.joinMethod : "link";

      await recordAnalyticsEvent({
        event: AnalyticsEvents.meetingJoined,
        uid: participantId,
        params: { role, join_method: joinMethod },
        source: "firestore_trigger",
      });

      if (isGuest) {
        await recordAnalyticsEvent({
          event: AnalyticsEvents.meetingGuestJoined,
          uid: participantId,
          params: {
            join_method: joinMethod,
            is_anonymous: Boolean(data.isAnonymous ?? false),
          },
          source: "firestore_trigger",
        });
      }
    } catch (e) {
      logger.warn(`analytics meeting_joined failed for ${meetingId}`, e);
    }
  }
);
