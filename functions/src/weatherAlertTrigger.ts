import { onDocumentUpdated } from "firebase-functions/v2/firestore";
import { getFirestore, FieldValue } from "firebase-admin/firestore";
import { getMessaging } from "firebase-admin/messaging";
import { initializeApp, getApps } from "firebase-admin/app";

if (getApps().length === 0) initializeApp();

/**
 * Firestore onDocumentUpdated-trigger som skickar FCM push-notis
 * nar hasActiveAlert andras fran false till true pa ett friend-dokument.
 *
 * Rate-limiting: Max 1 notis per van per 24 timmar via lastAlertSentAt.
 * Push-ton: Personlig och vanlig — "[Alert] hos [Namn]" + "Extremt vader i [Stad] — hor av dig!"
 */
export const onFriendAlertUpdated = onDocumentUpdated(
  {
    document: "users/{uid}/friends/{friendId}",
    region: "europe-west1",
  },
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!before || !after) return;

    // Kontrollera om hasActiveAlert andrades fran false/undefined till true
    const wasActive = before.hasActiveAlert === true;
    const isActive = after.hasActiveAlert === true;
    if (!isActive || wasActive) {
      // Ingen andring till active — skippa
      return;
    }

    // Rate-limiting: max 1 notis per 24 timmar
    const lastSent = after.lastAlertSentAt?.toDate();
    if (lastSent) {
      const hoursSince = (Date.now() - lastSent.getTime()) / (1000 * 60 * 60);
      if (hoursSince < 24) {
        console.log(
          `Rate limited: alert for friend ${event.params.friendId} sent ${hoursSince.toFixed(1)}h ago`
        );
        return;
      }
    }

    // Hamta agarens FCM-token
    const db = getFirestore();
    const userDoc = await db.collection("users").doc(event.params.uid).get();
    const fcmToken = userDoc.data()?.fcmToken;
    if (!fcmToken) {
      console.log(`No FCM token for user ${event.params.uid} — skipping push`);
      return;
    }

    // Hamta vannens information fran after-data
    const friendName = after.displayName ?? "En van";
    const friendCity = after.city ?? "";
    const alertSummary = after.alertSummary ?? "Extremt vader";

    // Deep link data — iOS-appen oppnar chatten via friend-context
    const data: Record<string, string> = {
      type: "weatherAlert",
      friendId: event.params.friendId,
      friendName,
      friendCity,
    };

    // Skicka FCM-push med personlig, vanlig ton
    const messaging = getMessaging();
    try {
      await messaging.send({
        token: fcmToken,
        notification: {
          title: `${alertSummary} hos ${friendName}`,
          body: friendCity
            ? `Extremt vader i ${friendCity} — hor av dig!`
            : `Hor av dig till ${friendName}!`,
        },
        data,
        apns: {
          payload: {
            aps: { sound: "default" },
          },
        },
      });
      console.log(
        `Weather alert push sent to ${event.params.uid} for friend ${friendName}`
      );
    } catch (error: unknown) {
      const errMsg = error instanceof Error ? error.message : String(error);
      console.error(`Failed to send weather alert push: ${errMsg}`);
      // Om token ar ogiltig, ta bort den
      if (errMsg.includes("registration-token-not-registered")) {
        await db
          .collection("users")
          .doc(event.params.uid)
          .set({ fcmToken: FieldValue.delete() }, { merge: true });
      }
    }

    // Uppdatera lastAlertSentAt for rate-limiting
    await db
      .collection("users")
      .doc(event.params.uid)
      .collection("friends")
      .doc(event.params.friendId)
      .update({ lastAlertSentAt: FieldValue.serverTimestamp() });
  }
);
