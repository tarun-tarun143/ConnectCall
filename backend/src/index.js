import 'dotenv/config';
import cors from 'cors';
import express from 'express';
import admin from 'firebase-admin';

const app = express();
app.use(cors());
app.use(express.json({ limit: '256kb' }));

const hasFirebaseAdminConfig = Boolean(
  process.env.FIREBASE_PROJECT_ID &&
  process.env.FIREBASE_CLIENT_EMAIL &&
  process.env.FIREBASE_PRIVATE_KEY,
);

if (hasFirebaseAdminConfig && admin.apps.length === 0) {
  admin.initializeApp({
    credential: admin.credential.cert({
      projectId: process.env.FIREBASE_PROJECT_ID,
      clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
      privateKey: process.env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n'),
    }),
  });
}

app.get('/health', (_req, res) => {
  res.json({
    ok: true,
    service: 'connectcall-backend',
    firebaseAdmin: Boolean(admin.apps.length),
  });
});

app.post('/api/notifications/call', async (req, res) => {
  if (!admin.apps.length) {
    return res.status(503).json({ error: 'Firebase Admin is not configured.' });
  }

  try {
    const { calleeId, title, body, data } = req.body ?? {};
    if (!calleeId) return res.status(400).json({ error: 'calleeId is required.' });

    const snapshot = await admin.firestore().collection('users').doc(calleeId).get();
    const tokens = Array.isArray(snapshot.get('fcmTokens')) ? snapshot.get('fcmTokens') : [];
    if (tokens.length === 0) return res.json({ sent: 0, failed: 0 });

    const message = {
      tokens,
      notification: {
        title: title ?? 'Incoming call',
        body: body ?? 'Someone is calling you.',
      },
      data: Object.fromEntries(
        Object.entries(data ?? {}).map(([key, value]) => [key, String(value)]),
      ),
      android: { priority: 'high' },
    };

    const result = await admin.messaging().sendEachForMulticast(message);
    return res.json({ sent: result.successCount, failed: result.failureCount });
  } catch (error) {
    console.error(error);
    return res.status(500).json({ error: 'Notification send failed.' });
  }
});

const port = Number(process.env.PORT ?? 8080);
app.listen(port, () => console.log(`[ConnectCall] backend listening on :${port}`));
