const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();
const db = admin.firestore();

// ✅ Cloud Function with manual ID token verification
exports.createAdmin = functions.https.onRequest(async (req, res) => {
  // ✅ CORS headers (important for mobile/web requests)
  res.set('Access-Control-Allow-Origin', '*');
  res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');
  res.set('Access-Control-Allow-Methods', 'POST');

  // ✅ Handle preflight request (CORS "OPTIONS" request)
  if (req.method === 'OPTIONS') {
    return res.status(204).send('');
  }

  // 🔒 Manual token extraction
  const idToken = req.headers.authorization?.split('Bearer ')[1];
  if (!idToken) {
    return res.status(401).json({ error: 'Missing token' });
  }

  let decoded;
  try {
    decoded = await admin.auth().verifyIdToken(idToken);
  } catch (error) {
    return res.status(401).json({ error: 'Invalid token' });
  }

  const callerUid = decoded.uid;
  const callerDoc = await db.collection('admins').doc(callerUid).get();

  if (!callerDoc.exists || callerDoc.data().role !== 'Super Admin') {
    return res.status(403).json({ error: 'Access denied' });
  }

  const { email, password, name, role } = req.body;
  if (!email || !password || !name || !role) {
    return res.status(400).json({ error: 'Missing fields' });
  }

  try {
    const newUser = await admin.auth().createUser({
      email,
      password,
      displayName: name,
    });

    await db.collection('admins').doc(newUser.uid).set({
      uid: newUser.uid,
      name,
      email,
      role,
      createdBy: callerUid,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return res.json({ message: 'Admin created', uid: newUser.uid });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ error: err.message });
  }
});


