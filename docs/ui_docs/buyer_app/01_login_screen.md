# 📱 Buyer App — Login Screen

> Page ID: `BUYER-01` | Priority: **P0 (Critical)** | Type: **Authentication**

---

## 1. Screen Overview

The Login Screen is the **first point of contact** for new and returning users. It collects the user's mobile number and initiates OTP-based authentication. This screen must feel trustworthy, simple, and fast — it sets the tone for the entire app experience.

---

## 2. UI Elements & Layout

### 2.1 Header Section
| Element | Description |
|---------|-------------|
| **App Logo** | OnWay Market brand logo — centered, prominent |
| **Tagline** | "Fresh from the street, right to you" — below logo |
| **Background Illustration** | Subtle animated illustration of a vendor cart moving on a map |

### 2.2 Login Form
| Element | Type | Description |
|---------|------|-------------|
| **Country Code Selector** | Dropdown | Default: `+91` (India). Flag icon + code |
| **Mobile Number Input** | Text Field | 10-digit number, numeric keyboard only |
| **Send OTP Button** | Primary CTA | Full-width, bold. Text: "Get OTP" |
| **Terms Text** | Small Text | "By continuing, you agree to our Terms & Privacy Policy" |

### 2.3 Footer
| Element | Description |
|---------|-------------|
| **Language Selector** | Small text link at bottom: "English | മലയാളം | हिन्दी" |
| **Version Number** | App version in subtle text |

---

## 3. UI States

| State | Description |
|-------|-------------|
| **Default** | Empty input, button disabled (greyed out) |
| **Input Active** | Input focused with accent border, button still disabled |
| **Valid Input** | 10 digits entered, button becomes active (solid color) |
| **Loading** | Button shows spinner, input becomes read-only |
| **Error** | Red border on input, error text below: "Please enter a valid mobile number" |
| **Rate Limited** | Toast/snackbar: "Too many attempts. Try again in 5 minutes" |

---

## 4. Design Pro Tips

### 🎨 Visual Design
- **Use a warm, earthy color palette** — greens and oranges work well for a marketplace that sells fresh produce. Avoid cold corporate blues.
- **Logo placement**: Keep the logo at ~30% from top. Users should see it without scrolling on any device.
- **Background**: Use a subtle gradient (e.g., `#F5F7E8` → `#FFFFFF`) — not a flat white. Feels more alive.
- **Micro-animation**: Animate the vendor cart illustration on load — a small cart sliding left-to-right gives life to the page.

### 📐 Layout & Spacing
- **Single-column center-aligned layout** — no distractions.
- **Input field**: Minimum height `52px`, generous internal padding (`16px horizontal`).
- **Button**: Minimum height `52px`, rounded corners (`12px`), bold text.
- **Spacing**: `24px` between logo and tagline, `32px` between tagline and input, `16px` between input and button.

### ⌨️ Input UX
- **Auto-focus the mobile input** on page load — save the user one tap.
- **Numeric keyboard only** — set `inputMode="numeric"` or `keyboardType="phone-pad"`.
- **Auto-format**: Show number as `98765 43210` (with space after 5 digits) for readability.
- **Max length validation**: Hard-stop at 10 digits.
- **Paste support**: Handle pasted numbers gracefully (strip spaces, `+91` prefix, etc.).

### 🔒 Trust Signals
- **Show a small lock icon** next to the input — signals security.
- **Terms & Privacy**: Make it a tappable link, not just text. Opens in an in-app browser.
- **No password required text**: "We'll send a one-time code to verify — no password needed"

### ♿ Accessibility
- **Contrast ratio**: Minimum 4.5:1 for all text.
- **Button disabled state**: Don't just change color — also change opacity and add a `disabled` attribute.
- **Screen reader labels**: "Enter your 10-digit mobile number" for the input field.

### ⚡ Performance
- **This screen must load in < 1 second** — it's the first thing users see.
- **Lazy-load the background illustration** — prioritize the form.
- **Preload the OTP screen assets** while user is typing.

---

## 5. User Flow

```
┌───────────────┐
│  App Launch    │
└───────┬───────┘
        │
        ▼
┌───────────────┐     ┌─────────────────┐
│  Login Screen │────▶│  Check Auth     │
│  (this page)  │     │  Token in Store  │
└───────┬───────┘     └────────┬────────┘
        │                      │
        │ (no token)           │ (valid token)
        ▼                      ▼
┌───────────────┐     ┌─────────────────┐
│  Enter Mobile │     │  Skip to Home   │
│  → Send OTP   │     │  Screen         │
└───────┬───────┘     └─────────────────┘
        │
        ▼
┌───────────────┐
│  OTP Screen   │
│  (BUYER-02)   │
└───────────────┘
```

---

## 6. Backend API Integration

### 6.1 Send OTP

| Property | Value |
|----------|-------|
| **Endpoint** | `POST /auth/send-otp` |
| **Auth Required** | ❌ No |
| **Rate Limited** | ✅ Yes — max 3 requests per 5 minutes per mobile |

**Request Body:**
```json
{
  "mobile": "9876543210"
}
```

**Success Response (200):**
```json
{
  "success": true,
  "data": {
    "message": "OTP sent successfully"
  }
}
```

**Error Responses:**

| Status | Code | Message | UI Action |
|--------|------|---------|-----------|
| 400 | `VALIDATION_ERROR` | "Mobile number is required" | Show inline error |
| 429 | `RATE_LIMITED` | "Too many OTP requests" | Show toast + disable button for cooldown |
| 500 | `INTERNAL_ERROR` | "Failed to send OTP" | Show retry dialog |

### 6.2 Integration Notes

- **Twilio Verify** is used under the hood — OTP is sent via SMS.
- OTP stored in Redis with 5-minute TTL.
- Frontend should **not** store or predict the OTP.
- On success, navigate to OTP Verification Screen (`BUYER-02`) and pass the mobile number.
- **Retry logic**: If the API fails with 500, allow one automatic retry after 3 seconds before showing error.

---

## 7. Validation Rules

| Field | Rule | Error Message |
|-------|------|---------------|
| Mobile | Required | "Mobile number is required" |
| Mobile | Exactly 10 digits | "Please enter a valid 10-digit mobile number" |
| Mobile | Digits only (no spaces, no +91) | "Only numbers are allowed" |

---

## 8. Analytics Events

| Event Name | Trigger | Properties |
|------------|---------|------------|
| `screen_view_login` | Screen opens | — |
| `login_input_started` | User starts typing | — |
| `login_otp_requested` | "Get OTP" tapped | `{ mobile_masked: "98***43210" }` |
| `login_otp_failed` | API returns error | `{ error_code }` |
| `login_rate_limited` | 429 response | — |

---

## 9. Edge Cases

| Scenario | Handling |
|----------|----------|
| No internet | Show offline banner: "No internet connection" |
| SMS not delivered | Handled on OTP screen (resend option) |
| User kills app during OTP send | Re-enter mobile on next launch |
| Deep link opens login | Pre-fill mobile if available |
| Already logged in | Auto-redirect to Home (check stored token) |

---

*Next Screen: [OTP Verification Screen →](./02_otp_verification_screen.md)*
