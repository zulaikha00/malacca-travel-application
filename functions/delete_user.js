const functions = require('firebase-functions/v2'); // v2 functions
const { admin } = require('./firebase'); // assuming you export initialized admin here

exports.deleteUserByUid = functions.https.onRequest(async (req, res) => {
  console.log('📥 Received request to delete user');

  if (req.method !== 'POST') {
    console.warn('❌ Method not allowed:', req.method);
    return res.status(405).send('Method Not Allowed');
  }

  const authHeader = req.headers.authorization || '';
  console.log('🔐 Auth header:', authHeader);

  const idToken = authHeader.startsWith('Bearer ') ? authHeader.split('Bearer ')[1] : null;
  if (!idToken) {
    console.error('❌ Missing ID token');
    return res.status(401).json({ error: 'Unauthorized: Missing ID token' });
  }

  try {
    const decodedToken = await admin.auth().verifyIdToken(idToken);
    const callerUid = decodedToken.uid;
    console.log('✅ Caller UID:', callerUid);

    const adminDoc = await admin.firestore().collection('admins').doc(callerUid).get();
    const role = adminDoc.exists ? adminDoc.data().role : null;
    console.log('👤 Role of caller:', role);

    if (role !== 'Admin' && role !== 'Super Admin') {
      console.warn('⛔ Unauthorized role');
      return res.status(403).json({ error: 'Forbidden: You must be Admin or Super Admin' });
    }

    const { uid } = req.body;
    console.log('🗑️ Deleting user UID:', uid);

    await admin.auth().deleteUser(uid);
    console.log('✅ Successfully deleted from Firebase Auth');

    await admin.firestore().collection('users').doc(uid).delete();
    console.log('✅ Successfully deleted from Firestore');

    return res.status(200).json({ success: true });
  } catch (err) {
    console.error('🔥 Error deleting user:', err);
    return res.status(500).json({ error: err.message });
  }
});

