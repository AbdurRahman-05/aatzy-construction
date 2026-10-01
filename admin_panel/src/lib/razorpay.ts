import Razorpay from 'razorpay';
import crypto from 'crypto';

export const YEARLY_MEMBERSHIP_FEE = Number(process.env.PROVIDER_YEARLY_MEMBERSHIP_FEE) || 5999;

export function getRazorpayClient(): Razorpay | null {
  const keyId = process.env.RAZORPAY_KEY_ID;
  const keySecret = process.env.RAZORPAY_KEY_SECRET;

  if (!keyId || !keySecret || keyId.includes('Example') || keyId.includes('placeholder')) {
    return null;
  }

  return new Razorpay({
    key_id: keyId,
    key_secret: keySecret,
  });
}

export function isRazorpayConfigured(): boolean {
  const keyId = process.env.RAZORPAY_KEY_ID;
  const keySecret = process.env.RAZORPAY_KEY_SECRET;
  return Boolean(keyId && keySecret && !keyId.includes('Example') && !keyId.includes('placeholder'));
}

export function getRazorpayKeyId(): string {
  return process.env.RAZORPAY_KEY_ID || 'rzp_test_51NgExampleKey';
}

export function verifyRazorpaySignature(
  orderId: string,
  paymentId: string,
  signature: string
): boolean {
  const secret = process.env.RAZORPAY_KEY_SECRET;
  if (!secret) return false;

  const body = `${orderId}|${paymentId}`;
  const expectedSignature = crypto
    .createHmac('sha256', secret)
    .update(body.toString())
    .digest('hex');

  return expectedSignature === signature;
}

export function calculateDaysLeft(expiresAt: Date | string | null | undefined): number {
  if (!expiresAt) return 0;
  const target = new Date(expiresAt).getTime();
  const now = Date.now();
  if (target <= now) return 0;
  return Math.ceil((target - now) / (1000 * 60 * 60 * 24));
}
