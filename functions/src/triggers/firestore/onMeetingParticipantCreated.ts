
import { onDocumentCreated } from "firebase-functions/v2/firestore";
import * as admin from "firebase-admin";

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
  }
);
