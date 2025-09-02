// ✅ firebase.js
// Purpose: Safely initialize Firebase Admin SDK and export Firestore and Storage

const admin = require('firebase-admin');

// ✅ Initialize only once to prevent "default app already exists" error
if (!admin.apps.length) {
  admin.initializeApp(); // Automatically picks up settings from .runtimeconfig.json or environment
}

// ✅ Firestore and Cloud Storage instances
const db = admin.firestore();
const bucket = admin.storage().bucket();

// ✅ Export for reuse in other files
module.exports = { admin, db, bucket };
