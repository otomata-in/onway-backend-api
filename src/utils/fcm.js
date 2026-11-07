const admin = require('firebase-admin');
const config = require('../config');
const path = require('path');
const fs = require('fs');

/**
 * Firebase Admin SDK initialization
 *
 * In production: Uses service account JSON file
 * In development: Gracefully degrades to console logging if no credentials
 */

let firebaseInitialized = false;

function initFirebase() {
  if (firebaseInitialized) return;

  try {
    const serviceAccountPath = path.resolve(config.firebase.serviceAccountPath);

    if (fs.existsSync(serviceAccountPath)) {
      const serviceAccount = require(serviceAccountPath);

      admin.initializeApp({
        credential: admin.credential.cert(serviceAccount),
      });

      firebaseInitialized = true;
      console.log('✅ Firebase Admin SDK initialized');
    } else {
      console.warn('⚠️  Firebase service account not found. FCM notifications will be logged to console.');
      console.warn(`   Expected at: ${serviceAccountPath}`);
      console.warn('   Download from: Firebase Console → Project Settings → Service Accounts');
    }
  } catch (error) {
    console.error('⚠️  Firebase initialization error:', error.message);
    console.warn('   FCM notifications will be logged to console.');
  }
}

/**
 * Send a push notification to a single device
 *
 * @param {string} fcmToken - The recipient's FCM token
 * @param {object} notification - { title, body }
 * @param {object} data - Additional data payload (all values must be strings)
 * @returns {Promise<string|null>} Message ID or null
 */
async function sendNotification(fcmToken, notification, data = {}) {
  if (!fcmToken) {
    return null;
  }

  // Stringify all data values (FCM requirement)
  const stringData = {};
  for (const [key, value] of Object.entries(data)) {
    stringData[key] = String(value);
  }

  const message = {
    token: fcmToken,
    notification: {
      title: notification.title,
      body: notification.body,
    },
    data: stringData,
    // Android-specific: high priority for time-sensitive notifications
    android: {
      priority: 'high',
      notification: {
        channelId: 'onway_default',
        sound: 'default',
      },
    },
    // APNs (iOS) config
    apns: {
      payload: {
        aps: {
          alert: {
            title: notification.title,
            body: notification.body,
          },
          sound: 'default',
          badge: 1,
        },
      },
    },
  };

  if (!firebaseInitialized) {
    // Dev mode: log to console
    console.log('📱 [FCM Dev] Push notification:');
    console.log(`   To: ${fcmToken.substring(0, 20)}...`);
    console.log(`   Title: ${notification.title}`);
    console.log(`   Body: ${notification.body}`);
    console.log(`   Data:`, stringData);
    return 'dev-mode-message-id';
  }

  try {
    const response = await admin.messaging().send(message);
    return response;
  } catch (error) {
    // Handle invalid/expired tokens
    if (
      error.code === 'messaging/invalid-registration-token' ||
      error.code === 'messaging/registration-token-not-registered'
    ) {
      console.warn(`⚠️  Invalid FCM token: ${fcmToken.substring(0, 20)}... — should be cleaned up`);
      // TODO: Remove invalid token from user record
    } else {
      console.error('FCM send error:', error.message);
    }
    return null;
  }
}

/**
 * Send push notification to multiple devices
 *
 * @param {string[]} fcmTokens - Array of FCM tokens
 * @param {object} notification - { title, body }
 * @param {object} data - Additional data payload
 * @returns {Promise<object>} { successCount, failureCount }
 */
async function sendMulticast(fcmTokens, notification, data = {}) {
  const validTokens = fcmTokens.filter(Boolean);
  if (validTokens.length === 0) return { successCount: 0, failureCount: 0 };

  // Stringify all data values
  const stringData = {};
  for (const [key, value] of Object.entries(data)) {
    stringData[key] = String(value);
  }

  if (!firebaseInitialized) {
    console.log(`📱 [FCM Dev] Multicast to ${validTokens.length} devices:`);
    console.log(`   Title: ${notification.title}`);
    console.log(`   Body: ${notification.body}`);
    return { successCount: validTokens.length, failureCount: 0 };
  }

  try {
    const message = {
      tokens: validTokens,
      notification: {
        title: notification.title,
        body: notification.body,
      },
      data: stringData,
      android: {
        priority: 'high',
        notification: {
          channelId: 'onway_default',
          sound: 'default',
        },
      },
    };

    const response = await admin.messaging().sendEachForMulticast(message);
    return {
      successCount: response.successCount,
      failureCount: response.failureCount,
    };
  } catch (error) {
    console.error('FCM multicast error:', error.message);
    return { successCount: 0, failureCount: validTokens.length };
  }
}

module.exports = { initFirebase, sendNotification, sendMulticast };
