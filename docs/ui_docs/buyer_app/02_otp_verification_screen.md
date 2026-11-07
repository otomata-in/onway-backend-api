# 🔐 Buyer App — OTP Verification Screen

> Page ID: `BUYER-02` | Priority: **P0 (Critical)** | Type: **Authentication**

---

## 1. Screen Overview

After entering their mobile number, the user is redirected here to input the 6-digit OTP. This screen verifies the user's identity and either creates a new account or logs them into an existing one. The experience should be **frictionless and fast** — ideally, the user spends < 15 seconds here.

---

## 2. UI Elements & Layout

### 2.1 Header
| Element | Description |
|---------|-------------|
| **Back Arrow** | Top-left, returns to Login Screen |
| **Title** | "Verify your number" |
| **Subtitle** | "We sent a code to **+91 98765 43210**" (formatted, bold number) |

### 2.2 OTP Input Section
| Element | Type | Description |
|---------|------|-------------|
| **OTP Input** | 6 separate digit boxes | Each box holds 1 digit. Auto-advance on input |
| **Auto-read Banner** | Info Text | "We'll try to auto-read the OTP from SMS" (if SMS permission granted) |

### 2.3 Action Section
| Element | Type | Description |
|---------|------|-------------|
| **Verify Button** | Primary CTA | "Verify & Continue" — active only when all 6 digits entered |
| **Resend Timer** | Countdown Text | "Resend OTP in **00:30**" — becomes tappable link after timer |
| **Resend Link** | Text Button | "Resend OTP" — appears after countdown ends |
| **Change Number** | Text Link | "Wrong number? Change" — navigates back to Login |

---

## 3. UI States

| State | Description |
|-------|-------------|
| **Default** | Empty OTP boxes, cursor on first box, button disabled |
| **Filling** | Digits appearing, auto-advancing to next box |
| **Complete** | All 6 filled, button becomes active, auto-submit (optional) |
| **Verifying** | Button shows spinner, inputs disabled |
| **Success** | Brief checkmark animation, then navigate to Home |
| **Error** | Boxes flash red, shake animation, error text: "Invalid OTP. Please try again" |
| **Expired** | Error text: "OTP expired. Please request a new one" + auto-enable resend |
| **Resend Available** | Timer reaches 0, "Resend OTP" link appears (blue, tappable) |

---

## 4. Design Pro Tips

### 🎨 Visual Design
- **Individual OTP boxes** (not a single input) — feels more modern and gives clear progress feedback.
- **Box size**: `48x52px` each with `12px` gap between. Use `2px` border, rounded `8px`.
- **Active box**: Thicker border (3px) in primary color. Empty boxes: light gray border.
- **Filled box**: Subtle background fill (e.g., `#F0F7ED`) to show completion.
- **Error state**: Red borders + subtle shake animation (CSS `@keyframes shake`).

### 📐 Layout
- **Center the OTP boxes** horizontally. On smaller screens, reduce gap to `8px`.
- **Generous top spacing**: OTP boxes should appear at ~35% from top — keep them in thumb-reach zone.
- **Resend timer**: Place directly below the OTP boxes, centered. Use monospace font for the countdown.

### ⌨️ Input UX
- **Auto-focus first box** on screen load.
- **Auto-advance**: When a digit is entered, automatically move focus to the next box.
- **Backspace behavior**: Pressing backspace clears current box and moves to previous box.
- **Paste support**: If user pastes a 6-digit code, distribute digits across all boxes.
- **SMS auto-read**: On Android, use the SMS Retriever API. On iOS, leverage the `one-time-code` input attribute.
- **Auto-submit**: Consider auto-submitting when the 6th digit is entered (saves a tap).

### ⏱️ Resend Logic
- **Initial cooldown**: 30 seconds (shown as countdown timer).
- **Progressive delay**: 2nd resend = 60s, 3rd resend = 120s (backoff to prevent abuse).
- **Max resends**: 3 per session. After that, show "Too many attempts" and redirect to Login.
- **Resend feedback**: Show toast "OTP resent!" on successful resend.

### 🎬 Animations
- **Entry**: Slide-up animation for the OTP section (300ms ease-out).
- **Digit entry**: Subtle scale-up (1.0 → 1.05 → 1.0) on the box when a digit is entered.
- **Error**: Shake animation (left-right oscillation, 300ms).
- **Success**: Checkmark circle animation (scale from 0 → 1 with green fill).

### ♿ Accessibility
- **Screen reader**: "Enter the 6-digit verification code sent to your phone"
- **Each box**: Label as "Digit 1 of 6", "Digit 2 of 6", etc.
- **Haptic feedback**: Light vibration on error (mobile).

---

## 5. User Flow

```
┌───────────────────┐
│  Login Screen     │
│  (BUYER-01)       │
└───────┬───────────┘
        │ OTP sent
        ▼
┌───────────────────┐
│  OTP Screen       │
│  (this page)      │
└───────┬───────────┘
        │
   ┌────┴─────┐
   │          │
   ▼          ▼
 Valid      Invalid
   │          │
   ▼          ▼
┌──────┐   ┌─────────────┐
│ New  │   │ Show Error   │
│ User?│   │ Allow Retry  │
└──┬───┘   └─────────────┘
   │
   ├── Yes ──▶ Home Screen (BUYER-03)
   │          (new user, role: buyer)
   │
   └── No ───▶ Home Screen (BUYER-03)
               (existing user, restore session)
```

---

## 6. Backend API Integration

### 6.1 Verify OTP

| Property | Value |
|----------|-------|
| **Endpoint** | `POST /auth/verify-otp` |
| **Auth Required** | ❌ No |

**Request Body:**
```json
{
  "mobile": "9876543210",
  "otp": "123456"
}
```

**Success Response (200):**
```json
{
  "success": true,
  "data": {
    "token": "uuid-auth-token-here",
    "user": {
      "id": 1,
      "mobile": "9876543210",
      "role": "buyer"
    }
  }
}
```

**Frontend Actions on Success:**
1. Store `token` securely (SecureStorage / Keychain / EncryptedSharedPreferences)
2. Store `user` object in app state
3. Set `Authorization: Bearer <token>` header for all future API calls
4. Register FCM token immediately (call `POST /users/fcm-token`)
5. Navigate to Home Screen

### 6.2 Resend OTP

| Property | Value |
|----------|-------|
| **Endpoint** | `POST /auth/send-otp` |
| **Auth Required** | ❌ No |

*Same endpoint as Login Screen — just re-call with the same mobile number.*

### 6.3 Error Handling

| Status | Code | Message | UI Action |
|--------|------|---------|-----------|
| 400 | `INVALID_OTP` | "Invalid or expired OTP" | Flash red, shake, show error text |
| 400 | `VALIDATION_ERROR` | "OTP must be 6 digits" | Show inline error |
| 429 | `RATE_LIMITED` | "Too many attempts" | Redirect to Login with message |
| 500 | `INTERNAL_ERROR` | "Verification failed" | Show retry option |

### 6.4 Post-Login API Call — Register FCM Token

| Property | Value |
|----------|-------|
| **Endpoint** | `POST /users/fcm-token` |
| **Auth Required** | ✅ Yes (Bearer token) |

**Request Body:**
```json
{
  "token": "fcm_device_token_here"
}
```

*Call this silently after successful login. Failure should not block the user.*

---

## 7. Data Flow

```
User Input (6 digits)
    │
    ▼
POST /auth/verify-otp { mobile, otp }
    │
    ├── Twilio Verify validates OTP
    ├── User upserted (findOrCreate)
    ├── UUID auth token generated
    ├── Token stored in auth_tokens table
    │
    ▼
Response: { token, user }
    │
    ▼
Frontend stores token → Registers FCM → Navigates to Home
```

---

## 8. Security Considerations

| Concern | Mitigation |
|---------|------------|
| Brute force OTP guessing | Rate limit: 3 attempts per 5 min |
| OTP replay attack | OTP invalidated after first use (Twilio handles this) |
| Token interception | Store in secure/encrypted storage only |
| Man-in-the-middle | All API calls over HTTPS |

---

## 9. Analytics Events

| Event Name | Trigger | Properties |
|------------|---------|------------|
| `screen_view_otp` | Screen opens | `{ mobile_masked }` |
| `otp_auto_read_success` | SMS auto-read fills OTP | — |
| `otp_submitted` | Verify button tapped | — |
| `otp_verified_success` | 200 response | `{ is_new_user }` |
| `otp_verified_failed` | Error response | `{ error_code }` |
| `otp_resend_tapped` | Resend link tapped | `{ resend_count }` |
| `otp_change_number` | Change number tapped | — |

---

*Previous: [← Login Screen](./01_login_screen.md) | Next: [Home Screen →](./03_home_screen.md)*
