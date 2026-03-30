const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const admin = require('firebase-admin');

// Initialize the admin SDK
try {
  admin.initializeApp();
} catch (e) {
  console.log('admin.initializeApp() error (probably already initialized):', e.message);
}

/**
 * Firestore trigger: when a notifications document is created, send an FCM
 * notification payload so the device OS displays the notification when the
 * app is backgrounded or terminated.
 */
exports.onNotificationCreate = onDocumentCreated('notifications/{docId}', async (event) => {
  const snap = event.data;
  if (!snap) {
    console.log('No data in event');
    return null;
  }

  const docId = event.params.docId;
  const data = snap.data() || {};

  const title = (data.title && data.title.toString()) || `${data.appName || 'StreetLight Monitor'}`;
  const body = (data.body && data.body.toString()) || (data.message && data.message.toString()) || '';

  // Enrich data payload so clients can dedupe and compose nicer titles
  const messageData = Object.assign({}, data, {
    notificationId: docId,
    notification_id: docId,
    docId: docId,
    appName: data.appName || 'StreetLight Monitor',
    lightName: data.lightName || data.name || '',
  });

  // Data-only payload: no 'notification' field so the OS does NOT auto-display
  // a notification. The Flutter app (foreground handler or background handler)
  // is solely responsible for showing the notification, which prevents the
  // duplicate-notification problem when the app is open.
  // title and body are included inside 'data' so the handlers can read them.
  const dataPayload = Object.keys(messageData).reduce((acc, key) => {
    try {
      acc[key] = typeof messageData[key] === 'string' ? messageData[key] : JSON.stringify(messageData[key]);
    } catch (e) {
      acc[key] = String(messageData[key]);
    }
    return acc;
  }, {});
  dataPayload['title'] = title;
  dataPayload['body'] = body;

  const fcmPayload = {
    data: dataPayload,
    android: {
      priority: 'high',
    },
    apns: {
      payload: {
        aps: {
          contentAvailable: true,
        },
      },
    },
  };

  // Send notifications ONLY to the user who owns the street light
  const promises = [];
  try {
    const targetUserId = data.userId || data.createdBy;
    
    if (!targetUserId) {
      console.log(`No userId found in notification doc=${docId} - skipping FCM send`);
      return null;
    }
    
    // Get this specific user's FCM tokens
    const userDoc = await admin.firestore().collection('users').doc(targetUserId).get();
    const tokens = [];
    
    if (userDoc.exists) {
      const userData = userDoc.data();
      if (userData && userData.fcmTokens && Array.isArray(userData.fcmTokens)) {
        tokens.push(...userData.fcmTokens);
      } else if (userData && userData.fcmToken) {
        tokens.push(userData.fcmToken); // Fallback to single token
      }
    }

    console.log(`Found ${tokens.length} FCM token(s) for user=${targetUserId}, notification doc=${docId}`);

    if (tokens.length > 0) {
      for (let i = 0; i < tokens.length; i += 500) {
        const batch = tokens.slice(i, i + 500);
        console.log(`Sending to ${batch.length} tokens (batch ${Math.floor(i / 500) + 1})`);
        
        const message = {
          data: fcmPayload.data,
          android: fcmPayload.android,
          apns: fcmPayload.apns,
          tokens: batch,
        };
        
        promises.push(admin.messaging().sendEachForMulticast(message));
      }

      const results = await Promise.all(promises);
      results.forEach((result, index) => {
        console.log(`Batch ${index + 1}: ${result.successCount} success, ${result.failureCount} failures`);
        if (result.failureCount > 0) {
          result.responses.forEach((resp, idx) => {
            if (!resp.success) {
              console.error(`Failed to send to token ${idx}:`, resp.error);
            }
          });
        }
      });
    } else {
      console.log('No FCM tokens found - skipping notification send');
    }
  } catch (err) {
    console.error('Error sending FCM for notification create:', err);
  }

  return null;
});
