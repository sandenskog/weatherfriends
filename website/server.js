const express = require('express');
const path = require('path');
const admin = require('firebase-admin');

// Initialize Firebase Admin with application default credentials
admin.initializeApp({
  credential: admin.credential.applicationDefault(),
});

const db = admin.firestore();
const app = express();
const PORT = process.env.PORT || 80;

// View engine
app.set('view engine', 'ejs');
app.set('views', path.join(__dirname, 'views'));

// AASA file — must be served with application/json content-type
app.get('/.well-known/apple-app-site-association', (req, res) => {
  res.setHeader('Content-Type', 'application/json');
  res.sendFile(path.join(__dirname, '.well-known', 'apple-app-site-association'));
});

// Invite route — dynamic page with OG tags and platform detection
app.get('/invite/:token', async (req, res) => {
  const { token } = req.params;

  try {
    const doc = await db.collection('invites').doc(token).get();

    if (!doc.exists) {
      return res.status(404).render('invite', { valid: false });
    }

    const data = doc.data();
    const userAgent = req.headers['user-agent'] || '';
    const isIOS = /iPhone|iPad|iPod/i.test(userAgent);
    const isAndroid = /Android/i.test(userAgent);

    res.render('invite', {
      valid: true,
      senderName: data.senderDisplayName || 'A friend',
      senderCity: data.senderCity || '',
      token,
      isIOS,
      isAndroid,
      appStoreUrl: 'https://apps.apple.com/app/id6760045281',
    });
  } catch (err) {
    console.error('Invite lookup error:', err.message);
    res.status(404).render('invite', { valid: false });
  }
});

// Static files (index.html, privacy.html, support.html)
app.use(express.static(path.join(__dirname, 'public')));

app.listen(PORT, () => {
  console.log(`FriendsCast website running on port ${PORT}`);
});
