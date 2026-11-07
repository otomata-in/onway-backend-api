# 🔐 Seller App — Login Screen

> Page ID: `SELLER-01` | Priority: **P0 (Critical)** | Type: **Authentication**

---

## 1. Screen Overview

Identical authentication flow to the Buyer App but with **seller-specific branding**. The login experience should visually communicate "this is for vendors" — using different illustrations and possibly a different color accent to distinguish it from the buyer app.

---

## 2. UI Elements & Layout

### 2.1 Header
| Element | Description |
|---------|-------------|
| **App Logo** | "OnWay Seller" branding — distinct from buyer app |
| **Tagline** | "Sell fresh, sell smart" |
| **Illustration** | Vendor cart illustration with route/map overlay |

### 2.2 Login Form
| Element | Type | Description |
|---------|------|-------------|
| **Country Code** | Dropdown | `+91` default |
| **Mobile Input** | Text Field | 10-digit numeric |
| **Send OTP** | Primary CTA | "Get Started" |
| **Terms** | Small Text | Terms & Privacy links |

### 2.3 New Vendor Banner
| Element | Type | Description |
|---------|------|-------------|
| **Info Text** | Banner | "New here? You'll be registered as a seller after login" |

---

## 3. Design Pro Tips

### 🎨 Differentiation from Buyer App
- **Color accent**: Use a warm orange/amber (`#FF8F00`) for the seller app vs the buyer app's green. This creates instant visual differentiation.
- **Typography**: Same font family, but seller app headers can use a bolder weight.
- **Illustration style**: Show a vendor's perspective — a cart with products, not a buyer browsing.
- **"Seller" label**: Always visible in the header — prevents confusion if user has both apps.

### 📱 New User Flow
- After OTP verification, if the user is NOT yet a seller:
  - Show the **Seller Registration Flow** (vehicle name input).
  - Then redirect to Dashboard.
- If already a seller: go directly to Dashboard.

---

## 4. Backend API Integration

### Same as Buyer App:
| API | Endpoint |
|-----|----------|
| Send OTP | `POST /auth/send-otp` |
| Verify OTP | `POST /auth/verify-otp` |
| Register FCM | `POST /users/fcm-token` |

### Post-Login Check:
- `GET /me` → check `role` field
  - If `role === "buyer"` → redirect to Seller Registration
  - If `role === "seller"` → redirect to Dashboard

### Seller Registration:
| Property | Value |
|----------|-------|
| **Endpoint** | `POST /seller/register` |
| **Auth Required** | ✅ Yes |
| **Request** | `{ "vehicle_name": "Fish Van" }` |

**Server-side actions:**
1. Creates Vendor record (is_active: false)
2. Upgrades user role from "buyer" to "seller" (transaction)
3. Returns updated user with vendor info

---

## 5. OTP Verification

Same screen as Buyer App (BUYER-02) with seller-specific styling. See [Buyer OTP Screen](../buyer_app/02_otp_verification_screen.md) for full specification.

**Additional seller-specific behavior:**
- After successful OTP, check if `user.role === "seller"`
- If not, show vehicle name input modal before proceeding

---

*Next: [Dashboard →](./02_dashboard.md)*
