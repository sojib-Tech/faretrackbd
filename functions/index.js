// ============================================================
// FIREBASE CLOUD FUNCTIONS
// OTP sending moved to client-side EmailJS system.
// See lib/services/email_service.dart
// ============================================================

const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { defineString } = require("firebase-functions/params");
const admin = require("firebase-admin");
admin.initializeApp();

const ADMIN_USERNAME = defineString("ADMIN_USERNAME", { default: "admin" });
// Keep the default requested by the app, but override this server-side before
// production deployment with: firebase functions:params:set ADMIN_PASSWORD.
const ADMIN_PASSWORD = defineString("ADMIN_PASSWORD", { default: "admin1234" });
const ADMIN_UID = "faretrackbd-admin";
const ADMIN_EMAIL = "admin@faretrackbd.local";

function requireAdmin(request) {
  if (!request.auth || request.auth.token.admin !== true) {
    throw new HttpsError("permission-denied", "Admin access required.");
  }
}

exports.adminLogin = onCall(async (request) => {
  const { username, password } = request.data || {};
  if (username !== ADMIN_USERNAME.value() || password !== ADMIN_PASSWORD.value()) {
    throw new HttpsError("permission-denied", "Invalid admin credentials.");
  }

  try {
    await admin.auth().getUser(ADMIN_UID);
  } catch (error) {
    if (error.code !== "auth/user-not-found") throw error;
    await admin.auth().createUser({
      uid: ADMIN_UID,
      email: ADMIN_EMAIL,
      displayName: "Administrator",
      emailVerified: true,
    });
  }

  await admin.auth().setCustomUserClaims(ADMIN_UID, { admin: true });
  const token = await admin.auth().createCustomToken(ADMIN_UID, { admin: true });
  return { token };
});

exports.adminDeleteProfile = onCall(async (request) => {
  requireAdmin(request);
  const uid = request.data?.uid;
  if (typeof uid !== "string" || !uid || uid === ADMIN_UID) {
    throw new HttpsError("invalid-argument", "A valid profile id is required.");
  }

  const history = await admin.firestore()
    .collection("trip_history")
    .where("userId", "==", uid)
    .get();
  const batch = admin.firestore().batch();
  batch.delete(admin.firestore().collection("users").doc(uid));
  history.docs.forEach((doc) => batch.delete(doc.ref));
  await batch.commit();
  try {
    await admin.auth().deleteUser(uid);
  } catch (error) {
    if (error.code !== "auth/user-not-found") throw error;
  }
  return { success: true };
});
