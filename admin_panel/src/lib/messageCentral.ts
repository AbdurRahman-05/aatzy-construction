// Simple in-memory cache to store mock OTP codes for simulator mode
const mockOtpCache = new Map<string, { code: string; phone: string; expires: number }>();

/**
 * Get Message Central API Credentials
 */
const getCredentials = () => {
  return {
    customerId: process.env.MESSAGE_CENTRAL_CUSTOMER_ID || '',
    // Key should be Base64 encoded password/API key
    key: process.env.MESSAGE_CENTRAL_KEY || '', 
    adminPhone: process.env.ADMIN_PHONE || '',
  };
};

/**
 * Fetch Authentication Token from Message Central
 */
async function getAuthToken(customerId: string, key: string): Promise<string | null> {
  try {
    const url = `https://cpaas.messagecentral.com/auth/v1/authentication/token?customerId=${customerId}&key=${key}&scope=NEW`;
    const response = await fetch(url, {
      method: 'GET',
      headers: { 'accept': '*/*' }
    });

    if (response.ok) {
      const data: any = await response.json();
      return data.token || data.authToken || null;
    }
    console.error('Message Central Auth Token API failed with status:', response.status);
    return null;
  } catch (error) {
    console.error('Failed to get Message Central Auth Token:', error);
    return null;
  }
}

/**
 * Send OTP via Message Central
 * Falls back to simulation mode if credentials are missing
 */
export async function sendOtp(phone: string): Promise<{ success: boolean; verificationId: string; error?: string }> {
  // Normalize phone number (remove +, spaces, ensure country code 91 is handled)
  let cleanPhone = phone.replace(/[\s+]/g, '');
  let countryCode = '91';
  
  if (cleanPhone.startsWith('91') && cleanPhone.length > 10) {
    cleanPhone = cleanPhone.substring(2);
  }

  const { customerId, key } = getCredentials();

  // If credentials are not configured, use Simulator Mode
  if (!customerId || !key || customerId === 'YOUR_CUSTOMER_ID' || key === 'YOUR_BASE64_KEY') {
    const mockCode = (Math.floor(1000 + Math.random() * 9000)).toString(); // 4-digit code
    const mockVerId = `mock_ver_${Math.random().toString(36).substring(2, 11)}`;
    
    // Store in cache for 10 minutes
    mockOtpCache.set(mockVerId, {
      code: mockCode,
      phone: cleanPhone,
      expires: Date.now() + 10 * 60 * 1000
    });

    console.log('\n==================================================');
    console.log(`[MESSAGE CENTRAL SIMULATOR]`);
    console.log(`Sending OTP to: +${countryCode} ${cleanPhone}`);
    console.log(`Verification Code: ${mockCode}`);
    console.log(`Verification ID: ${mockVerId}`);
    console.log('==================================================\n');

    return { success: true, verificationId: mockVerId };
  }

  try {
    const token = await getAuthToken(customerId, key);
    if (!token) {
      return { success: false, verificationId: '', error: 'Failed to authenticate with Message Central' };
    }

    const sendUrl = `https://cpaas.messagecentral.com/verification/v2/verification/send?countryCode=${countryCode}&customerId=${customerId}&flowType=SMS&mobileNumber=${cleanPhone}&otpLength=4`;
    const response = await fetch(sendUrl, {
      method: 'POST',
      headers: {
        'authToken': token,
        'accept': '*/*'
      }
    });

    const data: any = await response.json();
    if (response.ok && data.verificationId) {
      console.log(`Message Central OTP sent to ${phone}. VerificationID: ${data.verificationId}`);
      return { success: true, verificationId: data.verificationId };
    }

    console.error('Message Central send OTP failed:', data);
    return { success: false, verificationId: '', error: data.message || 'Failed to send SMS OTP' };
  } catch (error: any) {
    console.error('Message Central sendOtp error:', error);
    return { success: false, verificationId: '', error: error.message || 'SMS Service error' };
  }
}

/**
 * Validate OTP via Message Central
 * Validates mock verificationId locally if created by simulator
 */
export async function verifyOtp(phone: string, verificationId: string, code: string): Promise<{ success: boolean; error?: string }> {
  let cleanPhone = phone.replace(/[\s+]/g, '');
  if (cleanPhone.startsWith('91') && cleanPhone.length > 10) {
    cleanPhone = cleanPhone.substring(2);
  }

  // Handle Mock Verification IDs from simulator
  if (verificationId.startsWith('mock_ver_')) {
    const cached = mockOtpCache.get(verificationId);
    if (!cached) {
      return { success: false, error: 'OTP session expired or invalid' };
    }
    if (cached.expires < Date.now()) {
      mockOtpCache.delete(verificationId);
      return { success: false, error: 'OTP expired' };
    }
    if (cached.phone !== cleanPhone) {
      return { success: false, error: 'Mobile number mismatch' };
    }
    if (cached.code !== code.trim()) {
      return { success: false, error: 'Incorrect OTP code' };
    }
    // Success, delete from cache
    mockOtpCache.delete(verificationId);
    return { success: true };
  }

  const { customerId, key } = getCredentials();
  if (!customerId || !key) {
    return { success: false, error: 'Invalid mock session' };
  }

  try {
    const token = await getAuthToken(customerId, key);
    if (!token) {
      return { success: false, error: 'Failed to authenticate with Message Central' };
    }

    const validateUrl = `https://cpaas.messagecentral.com/verification/v2/verification/validateOtp?countryCode=91&mobileNumber=${cleanPhone}&verificationId=${verificationId}&customerId=${customerId}&code=${code}`;
    const response = await fetch(validateUrl, {
      method: 'POST',
      headers: {
        'authToken': token,
        'accept': '*/*'
      }
    });

    const data: any = await response.json();
    if (response.ok && data.status === 'VALIDATED') {
      return { success: true };
    }

    console.error('Message Central validation response:', data);
    return { success: false, error: data.message || 'Invalid or incorrect OTP' };
  } catch (error: any) {
    console.error('Message Central verifyOtp error:', error);
    return { success: false, error: error.message || 'SMS verification service error' };
  }
}
