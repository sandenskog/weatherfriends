import { onSchedule } from "firebase-functions/v2/scheduler";
import { getFirestore } from "firebase-admin/firestore";
import { initializeApp, getApps } from "firebase-admin/app";

if (getApps().length === 0) initializeApp();

/**
 * Schemalagd extremvader-kontroll — komplement till onFriendAlertUpdated.
 *
 * Primart ansvar: Rensa gamla alerts som iOS-klienten inte langre uppdaterar.
 * iOS-klienten satter hasActiveAlert vid app-start, men om anvandaren inte oppnar
 * appen pa lange kan gamla alerts ligga kvar. Denna scheduler rensar alerts aldre
 * an 24 timmar.
 *
 * Push-notiser skickas av weatherAlertTrigger.ts (onDocumentUpdated), INTE har.
 */
export const checkExtremeWeather = onSchedule(
  {
    schedule: "every 60 minutes",
    region: "europe-west1",
  },
  async (_event) => {
    const db = getFirestore();
    const cutoff = new Date(Date.now() - 24 * 60 * 60 * 1000);

    // Hamta alla users
    const usersSnap = await db.collection("users").get();
    let cleaned = 0;

    for (const userDoc of usersSnap.docs) {
      // Hamta vanner med aktiva alerts
      const friendsSnap = await userDoc.ref
        .collection("friends")
        .where("hasActiveAlert", "==", true)
        .get();

      for (const friendDoc of friendsSnap.docs) {
        const data = friendDoc.data();
        const lastSent = data.lastAlertSentAt?.toDate();

        // Om alert ar aldre an 24h, rensa
        if (lastSent && lastSent < cutoff) {
          await friendDoc.ref.update({
            hasActiveAlert: false,
            alertSummary: null,
          });
          cleaned++;
        }
      }
    }

    console.log(`checkExtremeWeather: Cleaned ${cleaned} stale alerts`);
  }
);
