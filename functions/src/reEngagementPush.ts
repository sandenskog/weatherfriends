import { onSchedule } from "firebase-functions/v2/scheduler";
import { getFirestore, Timestamp, FieldValue } from "firebase-admin/firestore";
import { getMessaging } from "firebase-admin/messaging";
import { initializeApp, getApps } from "firebase-admin/app";
import { canSendNotification, recordNotification } from "./notificationBudget";

if (getApps().length === 0) initializeApp();

/**
 * Re-engagement push notification — runs daily at 10:00 CET.
 *
 * Sends a push to users who haven't opened the app in 3+ days,
 * mentioning their top favorite friend by name.
 *
 * Guards:
 * - Only sends if lastReEngagementPushAt is >7 days ago (or missing)
 * - Respects notification budget (max 5 non-chat pushes/week)
 * - Requires valid fcmToken
 */
export const sendReEngagementPush = onSchedule(
  {
    schedule: "every day 10:00",
    timeZone: "Europe/Stockholm",
    region: "europe-west1",
  },
  async (_event) => {
    const db = getFirestore();
    const now = Timestamp.now();
    const threeDaysAgo = new Date(now.toMillis() - 3 * 24 * 60 * 60 * 1000);
    const sevenDaysAgo = new Date(now.toMillis() - 7 * 24 * 60 * 60 * 1000);

    // Query all users — filter in code since we need compound conditions
    const usersSnap = await db.collection("users").get();
    let sent = 0;
    let skipped = 0;

    for (const userDoc of usersSnap.docs) {
      const data = userDoc.data();
      const uid = userDoc.id;
      const fcmToken: string | undefined = data.fcmToken;

      // Must have a valid FCM token
      if (!fcmToken || fcmToken.length === 0) {
        continue;
      }

      // Check lastActiveAt — skip if active within 3 days
      const lastActive = data.lastActiveAt?.toDate?.();
      if (lastActive && lastActive > threeDaysAgo) {
        continue;
      }

      // Check lastReEngagementPushAt — skip if sent within 7 days
      const lastReEngagement = data.lastReEngagementPushAt?.toDate?.();
      if (lastReEngagement && lastReEngagement > sevenDaysAgo) {
        continue;
      }

      // Check notification budget
      const budgetOk = await canSendNotification(uid);
      if (!budgetOk) {
        skipped++;
        continue;
      }

      // Get a favorite friend's name for personalized message
      const friendName = await getTopFriendName(db, uid);
      const body = friendName
        ? `See what the weather is like for ${friendName} today`
        : "Check the weather where your friends are";

      try {
        const messaging = getMessaging();
        await messaging.send({
          token: fcmToken,
          notification: {
            title: "Miss your friends? 👋",
            body,
          },
          data: {
            type: "reEngagement",
          },
          apns: {
            payload: {
              aps: { sound: "default" },
            },
          },
        });

        // Record notification for budget tracking
        await recordNotification(uid);

        // Update lastReEngagementPushAt
        await db.collection("users").doc(uid).update({
          lastReEngagementPushAt: FieldValue.serverTimestamp(),
        });

        sent++;
      } catch (error) {
        // Token may be invalid — log and continue
        console.error(`Failed to send re-engagement push to ${uid}:`, error);

        // Clean up invalid token
        if (
          error instanceof Error &&
          error.message?.includes("registration-token-not-registered")
        ) {
          await db
            .collection("users")
            .doc(uid)
            .update({ fcmToken: FieldValue.delete() });
        }
      }
    }

    console.log(
      `sendReEngagementPush: sent=${sent}, skipped=${skipped} (budget exhausted)`
    );
  }
);

/**
 * Gets the display name of the user's first favorite friend,
 * or the first friend if no favorites exist.
 */
async function getTopFriendName(
  db: FirebaseFirestore.Firestore,
  uid: string
): Promise<string | null> {
  // Try favorites first
  const favSnap = await db
    .collection("users")
    .doc(uid)
    .collection("friends")
    .where("isFavorite", "==", true)
    .limit(1)
    .get();

  if (!favSnap.empty) {
    return favSnap.docs[0].data().displayName ?? null;
  }

  // Fall back to any friend
  const anySnap = await db
    .collection("users")
    .doc(uid)
    .collection("friends")
    .limit(1)
    .get();

  if (!anySnap.empty) {
    return anySnap.docs[0].data().displayName ?? null;
  }

  return null;
}
