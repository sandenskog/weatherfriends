import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { getFirestore, FieldValue } from "firebase-admin/firestore";
import { getMessaging } from "firebase-admin/messaging";
import { initializeApp, getApps } from "firebase-admin/app";

if (getApps().length === 0) initializeApp();

export const onNewMessage = onDocumentCreated(
  {
    document: "conversations/{conversationId}/messages/{messageId}",
    region: "europe-west1",
  },
  async (event) => {
    const messageData = event.data?.data();
    if (!messageData) {
      console.log("No message data found, skipping push.");
      return;
    }

    const { conversationId } = event.params;
    const senderId: string = messageData.senderId;
    const messageType: string = messageData.type ?? "text";
    const messageText: string = messageData.text ?? "";

    const db = getFirestore();

    // Hamta konversationsdokumentet for att fa participants-array
    const conversationSnap = await db
      .collection("conversations")
      .doc(conversationId)
      .get();

    if (!conversationSnap.exists) {
      console.log(`Conversation ${conversationId} not found, skipping push.`);
      return;
    }

    const conversationData = conversationSnap.data();
    const participants: string[] = conversationData?.participants ?? [];

    // Filtrera bort avsandaren — kvarstaende ar mottagare
    const recipients = participants.filter((uid) => uid !== senderId);

    if (recipients.length === 0) {
      console.log("No recipients after filtering sender, skipping push.");
      return;
    }

    // Blockerings-kontroll: kontrollera om avsandaren finns i mottagarens blockedUsers
    const unblockedRecipients: string[] = [];
    for (const recipientUid of recipients) {
      const blockedSnap = await db
        .collection("users")
        .doc(recipientUid)
        .collection("blockedUsers")
        .doc(senderId)
        .get();

      if (blockedSnap.exists) {
        console.log(
          `Recipient ${recipientUid} has blocked sender ${senderId}, skipping.`
        );
      } else {
        unblockedRecipients.push(recipientUid);
      }
    }

    if (unblockedRecipients.length === 0) {
      console.log("All recipients have blocked sender, skipping push.");
      return;
    }

    // Hamta FCM-tokens for alla ej-blockerade mottagare
    const tokenPromises = unblockedRecipients.map((uid) =>
      db.collection("users").doc(uid).get()
    );
    const userSnaps = await Promise.all(tokenPromises);

    const tokenToUid: Record<string, string> = {};
    const tokens: string[] = [];

    for (let i = 0; i < userSnaps.length; i++) {
      const userSnap = userSnaps[i];
      const fcmToken = userSnap.data()?.fcmToken;
      if (fcmToken && typeof fcmToken === "string" && fcmToken.length > 0) {
        tokens.push(fcmToken);
        tokenToUid[fcmToken] = unblockedRecipients[i];
      }
    }

    if (tokens.length === 0) {
      console.log("No valid FCM tokens found, skipping push.");
      return;
    }

    // Hamta avsandarens displayName
    const senderSnap = await db.collection("users").doc(senderId).get();
    const senderName: string =
      senderSnap.data()?.displayName ?? "En van";

    // Bestam body-text: vadersticker vs vanlig text
    const bodyText =
      messageType === "weatherSticker"
        ? "☁️ Skickade en vader-sticker"
        : messageText;

    // Skicka push-notis via FCM
    const messaging = getMessaging();
    const response = await messaging.sendEachForMulticast({
      tokens,
      notification: {
        title: senderName,
        body: bodyText,
      },
      data: {
        type: "chat",
        conversationId,
      },
      apns: {
        payload: {
          aps: { sound: "default" },
        },
      },
    });

    console.log(
      `Push sent: ${response.successCount} success, ${response.failureCount} failures`
    );

    // Hantera TokenNotRegistered-fel: ta bort ogiltiga tokens
    const invalidTokenUids: string[] = [];
    response.responses.forEach((resp, idx) => {
      if (
        !resp.success &&
        resp.error?.code === "messaging/registration-token-not-registered"
      ) {
        const token = tokens[idx];
        const uid = tokenToUid[token];
        if (uid) {
          invalidTokenUids.push(uid);
        }
      }
    });

    if (invalidTokenUids.length > 0) {
      console.log(`Removing invalid tokens for ${invalidTokenUids.length} users`);
      const cleanupPromises = invalidTokenUids.map((uid) =>
        db
          .collection("users")
          .doc(uid)
          .set({ fcmToken: FieldValue.delete() }, { merge: true })
      );
      await Promise.all(cleanupPromises);
    }
  }
);
