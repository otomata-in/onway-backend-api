# 🔔 Seller App — Notifications

> Page ID: `SELLER-11` | Priority: **P1 (High)** | Type: **Communication**

---

## 1. Screen Overview

Seller notifications focus on **order activity** and **demand insights**. When a buyer places an order token, the vendor receives an immediate notification. This screen shows the history of all such events.

---

## 2. Notification Types

| Type | Icon | Title | Body | Tap Action |
|------|------|-------|------|------------|
| `new_order` | 🛒 | "New Order Received!" | "You have a new order with 3 items" | Open Orders → specific order |
| `order_expired` | ⏰ | "Order Expired" | "An order expired (you passed the buyer)" | Open Orders |
| `route_demand` | 📊 | "High Demand Area" (future) | "3 buyers along your route are interested" | Open Map |

---

## 3. Design Pro Tips

### 🔔 Seller-Specific Urgency
- **New order = HIGH urgency**: Large font, vibration, sound. Seller must act fast.
- **Auto-dismiss timer**: If order isn't acted on in 10 minutes, notification becomes less prominent.
- **Action buttons in notification**: "Accept" / "Reject" directly in the push notification (rich notification).
- **Badge count**: Always show pending order count on the notification bell icon.
- **Sound differentiation**: New order gets a distinct chime. Expiry gets a softer tone.

---

## 4. Backend Integration

### FCM Push (Server → Seller)

| Notification | Trigger |
|-------------|---------|
| New order | Buyer creates order token → `POST /orders` triggers `notifyNewOrder()` |
| Order expired | Proximity exit zone → `proximity.js` triggers `notifyOrderExpired()` |

### Socket Events (Real-Time)

| Event | From | Action |
|-------|------|--------|
| `new_order` | order.service.js | Show notification + add to list |

### FCM Token

| Endpoint | `POST /users/fcm-token` |
|----------|------------------------|
| **Body** | `{ "token": "fcm_device_token" }` |

---

*Previous: [← Fulfillment](./10_fulfillment_screen.md)*
