import { initializeApp, getApps, cert } from 'firebase-admin/app';
import { getMessaging, Message, MulticastMessage } from 'firebase-admin/messaging';
import path from 'path';
import fs from 'fs';

let isFCMInitialized = false;

function initFirebaseAdmin() {
  if (isFCMInitialized) return true;
  if (getApps().length > 0) {
    isFCMInitialized = true;
    return true;
  }

  try {
    let serviceAccount: any = null;

    if (process.env.FIREBASE_SERVICE_ACCOUNT) {
      try {
        serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
      } catch {
        const decoded = Buffer.from(process.env.FIREBASE_SERVICE_ACCOUNT, 'base64').toString('utf8');
        serviceAccount = JSON.parse(decoded);
      }
    } else {
      const candidates = [
        path.join(process.cwd(), 'firebase-service-account.json'),
        path.join(process.cwd(), 'firebase-service-account.json.json'),
        path.join(process.cwd(), 'admin_panel', 'firebase-service-account.json'),
      ];

      for (const p of candidates) {
        if (fs.existsSync(p)) {
          serviceAccount = JSON.parse(fs.readFileSync(p, 'utf8'));
          break;
        }
      }
    }

    if (serviceAccount && serviceAccount.project_id) {
      initializeApp({
        credential: cert(serviceAccount),
      });
      isFCMInitialized = true;
      console.log(`[FCM] Firebase Admin SDK initialized successfully for project: ${serviceAccount.project_id}`);
      return true;
    } else {
      console.log('[FCM] Note: firebase-service-account.json not found in admin_panel directory. Closed-phone push will be active once key is placed.');
      return false;
    }
  } catch (error) {
    console.error('[FCM] Firebase Admin initialization error:', error);
    return false;
  }
}

export async function sendFCMNotification(params: {
  token: string;
  title: string;
  body: string;
  route?: string;
  channelId?: string;
  senderId?: string; // Used for chat suppression on the Flutter side
  recipientId?: string; // Used to ensure the notification is delivered only to the active logged-in user
  role?: string;
}) {
  if (!params.token) return;
  if (!initFirebaseAdmin()) return;

  try {
    const message: Message = {
      token: params.token,
      notification: {
        title: params.title,
        body: params.body,
      },
      data: {
        title: params.title,
        body: params.body,
        route: params.route || '/notifications',
        click_action: 'FLUTTER_NOTIFICATION_CLICK',
        ...(params.senderId ? { senderId: params.senderId, entityId: params.senderId } : {}),
        ...(params.recipientId ? { recipientId: params.recipientId } : {}),
        ...(params.role ? { role: params.role } : {}),
      },
      android: {
        priority: 'high',
        notification: {
          channelId: params.channelId || 'buildzy_leads_v2',
          sound: 'default',
          priority: 'max',
          defaultVibrateTimings: true,
          visibility: 'public',
        },
      },
    };

    const response = await getMessaging().send(message);
    console.log(`[FCM] Successfully delivered closed-app push notification: ${response}`);
  } catch (error: any) {
    console.error('[FCM] Failed to deliver FCM push notification:', error?.message || error);
  }
}

export async function sendMulticastFCM(params: {
  tokens: string[];
  title: string;
  body: string;
  route?: string;
  channelId?: string;
}) {
  const validTokens = (params.tokens || []).filter(t => t && t.trim().length > 0);
  if (validTokens.length === 0) return;
  if (!initFirebaseAdmin()) return;

  try {
    const message: MulticastMessage = {
      tokens: validTokens,
      notification: {
        title: params.title,
        body: params.body,
      },
      data: {
        title: params.title,
        body: params.body,
        route: params.route || '/notifications',
        click_action: 'FLUTTER_NOTIFICATION_CLICK',
      },
      android: {
        priority: 'high',
        notification: {
          channelId: params.channelId || 'buildzy_leads_v2',
          sound: 'default',
          priority: 'max',
          defaultVibrateTimings: true,
          visibility: 'public',
        },
      },
    };

    const response = await getMessaging().sendEachForMulticast(message);
    console.log(`[FCM Multicast] Sent to ${validTokens.length} devices: ${response.successCount} succeeded, ${response.failureCount} failed.`);
  } catch (error: any) {
    console.error('[FCM Multicast] Error sending multicast push:', error?.message || error);
  }
}
