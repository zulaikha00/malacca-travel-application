const functions = require('firebase-functions/v2');
const { admin } = require('./firebase');

exports.deleteAdminByUid = functions.https.onRequest(async (req, res) => {
  console.log('📥 Received request to delete admin');

  if (req.method !== 'POST') {
    console.warn('❌ Method not allowed:', req.method);
    return res.status(405).send('Method Not Allowed');
  }

  const authHeader = req.headers.authorization || '';
  const idToken = authHeader.startsWith('Bearer ') ? authHeader.split('Bearer ')[1] : null;

  if (!idToken) {
    console.error('❌ Missing ID token');
    return res.status(401).json({ error: 'Unauthorized: Missing ID token' });
  }

  try {
    const decodedToken = await admin.auth().verifyIdToken(idToken);
    const callerUid = decodedToken.uid;
    console.log('✅ Caller UID:', callerUid);

    const callerDoc = await admin.firestore().collection('admins').doc(callerUid).get();
    const callerRole = callerDoc.exists ? callerDoc.data().role : null;
    console.log('👤 Role of caller:', callerRole);

    // Only Super Admins can delete Admins
    if (callerRole !== 'Super Admin') {
      console.warn('⛔ Unauthorized: Only Super Admin can delete admins');
      return res.status(403).json({ error: 'Forbidden: Only Super Admin can delete admins' });
    }

    const { uid } = req.body;
    if (!uid) {
      return res.status(400).json({ error: 'Bad Request: Missing uid in body' });
    }
    console.log('🗑️ Deleting admin UID:', uid);

    await admin.auth().deleteUser(uid);
    console.log('✅ Successfully deleted from Firebase Auth');

    await admin.firestore().collection('admins').doc(uid).delete();
    console.log('✅ Successfully deleted from Firestore (admins collection)');

    return res.status(200).json({ success: true, message: 'Admin successfully deleted' });
  } catch (err) {
    console.error('🔥 Error deleting admin:', err);
    return res.status(500).json({ error: err.message });
  }
});
