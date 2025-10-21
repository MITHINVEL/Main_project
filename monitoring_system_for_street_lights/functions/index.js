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

    // Send to specific user topic if userId available, otherwise send to global topic
    const promises = [];
    try {
      if (data.userId) {
        const topic = `user_${data.userId}`;
        console.log(`Sending notification for doc=${docId} to topic=${topic}`);
        promises.push(admin.messaging().sendToTopic(topic, fcmPayload));
      } else {
        // No specific user - broadcast to global alerts topic
        console.log(`No userId - sending notification for doc=${docId} to topic=street_lights_alerts`);
        promises.push(admin.messaging().sendToTopic('street_lights_alerts', fcmPayload));
      }

      const results = await Promise.all(promises);
      console.log('FCM send results:', results.map(r => (r && r.results) ? r.results : r));
    } catch (err) {
      console.error('Error sending FCM for notification create:', err);
    }

    return null;
  });
