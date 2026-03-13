import { getFirestore, Timestamp, FieldValue } from "firebase-admin/firestore";

/**
 * Notification budget — limits non-chat push notifications per user per week.
 *
 * Budget is tracked in `users/{uid}.notificationBudget`:
 * - count: number of non-chat pushes sent this week
 * - weekStart: Timestamp of the current budget week's Monday 00:00 UTC
 *
 * Max: 5 non-chat notifications per week.
 * Week resets on Monday 00:00 UTC.
 *
 * Chat push (chatPushTrigger) is NOT subject to budget.
 */

const MAX_WEEKLY_NOTIFICATIONS = 5;

/**
 * Returns the Monday 00:00 UTC timestamp for the current week.
 */
function getCurrentWeekStart(): Date {
  const now = new Date();
  const day = now.getUTCDay(); // 0=Sunday, 1=Monday, ...
  const diff = day === 0 ? 6 : day - 1; // Days since Monday
  const monday = new Date(now);
  monday.setUTCDate(now.getUTCDate() - diff);
  monday.setUTCHours(0, 0, 0, 0);
  return monday;
}

/**
 * Checks if a non-chat notification can be sent to this user.
 * Returns true if under the weekly budget, false if exhausted.
 */
export async function canSendNotification(uid: string): Promise<boolean> {
  const db = getFirestore();
  const userDoc = await db.collection("users").doc(uid).get();
  const data = userDoc.data();

  if (!data?.notificationBudget) {
    // No budget tracked yet — allowed
    return true;
  }

  const budget = data.notificationBudget;
  const currentWeekStart = getCurrentWeekStart();
  const budgetWeekStart = budget.weekStart?.toDate?.();

  // If the budget is from a previous week, reset — allowed
  if (!budgetWeekStart || budgetWeekStart < currentWeekStart) {
    return true;
  }

  // Check count against limit
  return (budget.count ?? 0) < MAX_WEEKLY_NOTIFICATIONS;
}

/**
 * Records a sent non-chat notification against the user's weekly budget.
 * Resets the counter if we're in a new week.
 */
export async function recordNotification(uid: string): Promise<void> {
  const db = getFirestore();
  const userRef = db.collection("users").doc(uid);
  const userDoc = await userRef.get();
  const data = userDoc.data();

  const currentWeekStart = getCurrentWeekStart();
  const currentWeekTimestamp = Timestamp.fromDate(currentWeekStart);

  if (!data?.notificationBudget) {
    // First notification ever
    await userRef.set(
      {
        notificationBudget: {
          count: 1,
          weekStart: currentWeekTimestamp,
        },
      },
      { merge: true }
    );
    return;
  }

  const budgetWeekStart = data.notificationBudget.weekStart?.toDate?.();

  if (!budgetWeekStart || budgetWeekStart < currentWeekStart) {
    // New week — reset counter
    await userRef.set(
      {
        notificationBudget: {
          count: 1,
          weekStart: currentWeekTimestamp,
        },
      },
      { merge: true }
    );
  } else {
    // Same week — increment
    await userRef.update({
      "notificationBudget.count": FieldValue.increment(1),
    });
  }
}
