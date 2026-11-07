# ⚙️ Buyer App — Profile & Settings

> Page ID: `BUYER-10` | Priority: **P2 (Medium)** | Type: **Account Management**

---

## 1. Screen Overview

The Profile & Settings screen lets users manage their account details, saved locations, notification preferences, language, and app information. It also provides the **"Become a Seller"** upgrade path for buyers who want to start selling.

---

## 2. UI Elements & Layout

### 2.1 Profile Header
| Element | Type | Description |
|---------|------|-------------|
| **Avatar** | Circle | Generated avatar from initials or user-uploaded photo (future) |
| **Mobile Number** | Title | "+91 98765 43210" |
| **Role Badge** | Chip | "Buyer" or "Seller" |
| **Edit Profile** | Icon Button | Future: edit name, photo |

### 2.2 Saved Locations Section
| Element | Type | Description |
|---------|------|-------------|
| **Home** | List Item | 🏠 "Home" + address. Tap to change |
| **Work** | List Item | 🏢 "Work" + address. Tap to change |
| **Add Location** | Button | "+ Add Saved Location" |

### 2.3 Favorites Section
| Element | Type | Description |
|---------|------|-------------|
| **Favorite Vendors** | List Item | "♥ My Favorite Vendors" → navigates to favorites list |

### 2.4 Settings Section
| Element | Type | Description |
|---------|------|-------------|
| **Notifications** | Toggle + Link | "Push Notifications" toggle + "Manage Preferences" link |
| **Language** | Selector | "English" / "മലയാളം" / "हिन्दी" |
| **Search Radius** | Slider | "Default search radius: 5 km" — adjustable 1-10 km |

### 2.5 Seller Section
| Element | Type | Description |
|---------|------|-------------|
| **Become a Seller** | Prominent CTA | "🚚 Start Selling on OnWay" — opens seller registration |
| **Already Seller** | Link | If role=seller: "Switch to Seller App →" |

### 2.6 App Section
| Element | Type | Description |
|---------|------|-------------|
| **About** | Link | App version + info |
| **Terms & Privacy** | Link | Opens Terms of Service / Privacy Policy |
| **Help & Support** | Link | FAQ / Contact |
| **Logout** | Destructive Button | "Log Out" — with confirmation dialog |

---

## 3. Design Pro Tips

### 👤 Profile Header
- **Avatar**: Use initials from mobile number (last 2 digits as background color seed). Circle, 72px diameter.
- **Gradient background**: Subtle gradient behind the profile section — gives it a "premium card" feel.
- **Role badge**: Small pill badge below the number. Green for Buyer, Purple for Seller.

### ⚙️ Settings Items
- **List item height**: 56px minimum for touch targets.
- **Icons**: Use consistent icon set (outlined style). Left-aligned, 24px.
- **Toggles**: Use standard iOS/Android toggle style. Green when on.
- **Section dividers**: Use section headers ("Account", "Preferences", "About") with uppercase, small, muted text.

### 🚚 Seller CTA
- **Make it prominent**: Card-style with gradient background. Not just a list item.
- **Illustration**: Small illustration of a vendor cart.
- **Only show for buyers**: Hide if user is already a seller.

### 🔐 Logout
- **Red text**: Use red/destructive color for logout.
- **Confirmation dialog**: "Are you sure you want to log out?" with "Cancel" and "Log Out" buttons.
- **Clear all data**: On logout, clear token, user data, FCM token, and socket connection.

---

## 4. Backend API Integration

### 4.1 Get User Profile

| Property | Value |
|----------|-------|
| **Endpoint** | `GET /me` |
| **Auth Required** | ✅ Yes |

**Response:**
```json
{
  "success": true,
  "data": {
    "id": 1,
    "mobile": "9876543210",
    "role": "buyer",
    "fcm_token": "fcm_...",
    "created_at": "2026-01-15T10:00:00Z",
    "vendor": null
  }
}
```

### 4.2 Update Location

| Property | Value |
|----------|-------|
| **Endpoint** | `PUT /me/location` |
| **Auth Required** | ✅ Yes |

**Request:** `{ "lat": 10.12, "lng": 76.34 }`

### 4.3 Register as Seller

| Property | Value |
|----------|-------|
| **Endpoint** | `POST /seller/register` |
| **Auth Required** | ✅ Yes |

**Request:** `{ "vehicle_name": "Fish Van" }`

**Response:** Updated user with `role: "seller"` + vendor record.

**Flow:**
1. User taps "Start Selling"
2. Show registration form (vehicle name)
3. Call `POST /seller/register`
4. On success: update local user data, show success, offer to switch to Seller App

### 4.4 Get Favorite Vendors

| Property | Value |
|----------|-------|
| **Endpoint** | `GET /vendors/favorites` |
| **Auth Required** | ✅ Yes |

### 4.5 Logout

| Property | Value |
|----------|-------|
| **Endpoint** | `POST /auth/logout` |
| **Auth Required** | ✅ Yes |

**Frontend Actions on Logout:**
1. Call `POST /auth/logout` (invalidates server-side token)
2. Clear stored auth token
3. Clear user data from state
4. Disconnect Socket.IO
5. Navigate to Login Screen

---

## 5. Analytics Events

| Event Name | Trigger | Properties |
|------------|---------|------------|
| `screen_view_profile` | Screen opens | `{ role }` |
| `become_seller_tapped` | CTA tapped | — |
| `seller_registered` | Registration success | — |
| `language_changed` | Language selected | `{ language }` |
| `search_radius_changed` | Radius adjusted | `{ radius_km }` |
| `logout_confirmed` | Logout confirmed | — |

---

*Previous: [← Orders/History](./09_orders_history_page.md)*
