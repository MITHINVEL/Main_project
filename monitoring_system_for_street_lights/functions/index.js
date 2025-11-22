const functions = require('firebase-functions');
const admin = require('firebase-admin');

// Initialize the admin SDK
try {
  admin.initializeApp();
} catch (e) {
  // initializeApp can be called multiple times in the emulator; ignore errors
  console.log('admin.initializeApp() error (probably already initialized):', e.message);
}

/**
 * Firestore trigger: when a notifications document is created, send an FCM
 * notification payload so the device OS displays the notification when the
 * app is backgrounded or terminated.
 *
 * Writes should include fields like:
 *  - title, body (optional)
 *  - userId (target user)
 *  - lightId / lightName
 */
exports.onNotificationCreate = functions.firestore
  .document('notifications/{docId}')
  .onCreate(async (snap, context) => {
    const docId = context.params.docId;
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

    const fcmPayload = {
      notification: {
        title: title,
        body: body,
      },
      data: Object.keys(messageData).reduce((acc, key) => {
        // Firebase requires string values for data payload
        try {
          acc[key] = typeof messageData[key] === 'string' ? messageData[key] : JSON.stringify(messageData[key]);
        } catch (e) {
          acc[key] = String(messageData[key]);
        }
        return acc;
      }, {}),
      android: {
        priority: 'high',
        notification: {
          channelId: 'street_lights_channel',
          defaultSound: 'default',
        },
      },
      apns: {
        payload: {
          aps: {
            sound: 'default',
            contentAvailable: true,
            category: 'STREET_LIGHTS',
          },
        },
      },
    };

    // Send notifications ONLY to the user who owns the street light
    const promises = [];
    try {
      // Get the userId from the notification document
      const targetUserId = data.userId || data.createdBy;
      
      if (!targetUserId) {
        console.log(`No userId found in notification doc=${docId} - skipping FCM send`);
        return null;
      }
      
      // Get only this specific user's FCM token
      const userDoc = await admin.firestore().collection('users').doc(targetUserId).get();
      const tokens = [];
      
      if (userDoc.exists) {
        const userData = userDoc.data();
        if (userData && userData.fcmToken) {
          tokens.push(userData.fcmToken);
        }
      }

      console.log(`Found ${tokens.length} FCM token(s) for user=${targetUserId}, notification doc=${docId}`);

      if (tokens.length > 0) {
        // Send to all tokens (batch of 500 max per call)
        for (let i = 0; i < tokens.length; i += 500) {
          const batch = tokens.slice(i, i + 500);
          console.log(`Sending to ${batch.length} tokens (batch ${Math.floor(i / 500) + 1})`);
          
          const message = {
            notification: fcmPayload.notification,
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
