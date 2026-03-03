import { onSchedule } from "firebase-functions/v2/scheduler";
import { initializeApp, getApps } from "firebase-admin/app";

if (getApps().length === 0) initializeApp();

/**
 * Schemalagd extremvader-kontroll — PLACEHOLDER for v1.
 *
 * Full implementation väntar på att iOS-klienten levererar alert-data till Firestore.
 *
 * Planerad arkitektur (Alternativ A, rekommenderas):
 * - iOS-klienten kontrollerar WeatherKit weatherAlerts vid app-start/background refresh.
 * - iOS-klienten sparar `hasActiveAlert: true/false` + `alertSummary: "Storm"` per vän
 *   i Firestore: users/{uid}/friends/{friendId}.
 * - Cloud Function triggas av Firestore onDocumentUpdated när hasActiveAlert ändras
 *   från false till true, och skickar push-notis till vänens ägare.
 *
 * Nuvarande status: Funktionen loggar att den körs men gör inga faktiska kontroller
 * tills iOS-klienten levererar alert-data.
 *
 * TODO (fas 5 eller senare):
 * - Lyssna på users/{uid}/friends/{friendId} Firestore-uppdateringar
 * - Kontrollera hasActiveAlert-fältet
 * - Skicka FCM-push med rate-limiting (max 1 notis per vän per dag via lastAlertSentAt)
 */
export const checkExtremeWeather = onSchedule(
  {
    schedule: "every 60 minutes",
    region: "europe-west1",
  },
  async (_event) => {
    console.log(
      "checkExtremeWeather: Weather alert check running — waiting for iOS client integration."
    );
    console.log(
      "checkExtremeWeather: iOS client should set hasActiveAlert in Firestore users/{uid}/friends/{friendId} when WeatherKit reports extreme weather."
    );
    // Placeholder — ingen faktisk logik tills iOS-klienten levererar alert-data till Firestore.
    return;
  }
);
