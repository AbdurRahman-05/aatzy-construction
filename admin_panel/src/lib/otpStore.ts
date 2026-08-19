// In-memory OTP storage for Email Password Resets

interface StoredOtp {
  otp: string;
  role?: string;
  expiresAt: number;
}

// Map key: lowercased email address
const otpMap = new Map<string, StoredOtp>();

export function storePasswordResetOtp(email: string, otp: string, role?: string, ttlMinutes: number = 10) {
  const normalizedEmail = email.trim().toLowerCase();
  const expiresAt = Date.now() + ttlMinutes * 60 * 1000;
  otpMap.set(normalizedEmail, { otp, role, expiresAt });
}

export function verifyPasswordResetOtp(email: string, otp: string): { valid: boolean; role?: string; error?: string } {
  const normalizedEmail = email.trim().toLowerCase();
  const stored = otpMap.get(normalizedEmail);

  if (!stored) {
    return { valid: false, error: 'No verification code was requested for this email. Please request a new one.' };
  }

  if (Date.now() > stored.expiresAt) {
    otpMap.delete(normalizedEmail);
    return { valid: false, error: 'Verification code has expired. Please request a new one.' };
  }

  if (stored.otp.trim() !== otp.trim()) {
    return { valid: false, error: 'Incorrect verification code. Please check your email.' };
  }

  return { valid: true, role: stored.role };
}

export function clearPasswordResetOtp(email: string) {
  const normalizedEmail = email.trim().toLowerCase();
  otpMap.delete(normalizedEmail);
}
