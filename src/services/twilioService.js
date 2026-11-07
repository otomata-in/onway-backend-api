const twilio = require('twilio');

const accountSid = process.env.TWILIO_ACCOUNT_SID;
const authToken = process.env.TWILIO_AUTH_TOKEN;
const serviceSid = process.env.TWILIO_SERVICE_SID;

let client = null;
if (accountSid && authToken) {
  try {
    client = twilio(accountSid, authToken);
  } catch (err) {
    console.error('[Twilio Init Error]', err.message);
  }
}

/**
 * Generate a 5-digit numeric OTP code
 */
function generateOtpCode() {
  return Math.floor(10000 + Math.random() * 90000).toString();
}

/**
 * Send SMS Verification OTP via Twilio Verify V2 API (Zipfoo credential setup)
 */
async function sendSmsOtp(phoneNumber, customOtpCode) {
  const formattedPhone = phoneNumber.startsWith('+') ? phoneNumber : `+91${phoneNumber}`;

  if (client && serviceSid) {
    try {
      const verification = await client.verify.v2
        .services(serviceSid)
        .verifications
        .create({ to: formattedPhone, channel: 'sms' });

      console.log(`[Twilio Verify Sent] SID: ${verification.sid} to ${formattedPhone}`);
      return { success: true, sid: verification.sid, status: verification.status };
    } catch (err) {
      console.error(`[Twilio Verify Error] ${err.message}`);
      return { success: false, error: err.message };
    }
  } else {
    console.log(`[Twilio Mock Mode] Sent OTP ${customOtpCode || '123456'} to ${formattedPhone}`);
    return { success: true, mock: true };
  }
}

/**
 * Verify OTP Code via Twilio Verify V2 API
 */
async function checkSmsOtp(phoneNumber, code) {
  const formattedPhone = phoneNumber.startsWith('+') ? phoneNumber : `+91${phoneNumber}`;

  if (client && serviceSid) {
    try {
      const check = await client.verify.v2
        .services(serviceSid)
        .verificationChecks
        .create({ to: formattedPhone, code });

      console.log(`[Twilio Verify Check] ${formattedPhone} status: ${check.status}`);
      return { success: check.status === 'approved', status: check.status };
    } catch (err) {
      console.error(`[Twilio Verify Check Error] ${err.message}`);
      return { success: false, error: err.message };
    }
  }

  return { success: code === '123456', mock: true };
}

module.exports = {
  generateOtpCode,
  sendSmsOtp,
  checkSmsOtp,
};
