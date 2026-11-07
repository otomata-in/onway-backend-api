# 🔔 Buyer App — Notifications

> Page ID: `BUYER-08` | Priority: **P1 (High)** | Type: **Communication**

---

## 1. Screen Overview

The Notifications screen aggregates all push notifications and real-time alerts the buyer has received. It serves as a **history log** and quick-access point for order updates, proximity alerts, and vendor activity.

---

## 2. UI Elements & Layout

### 2.1 Header
| Element | Type | Description |
|---------|------|-------------|
| **Back Arrow** | Icon Button | Returns to Home |
| **Title** | Text | "Notifications" |
| **Mark All Read** | Text Button | "Mark all as read" — appears when unread exist |

### 2.2 Notification List
| Element | Type | Description |
|---------|------|-------------|
| **Notification Card** | List Item | Icon + title + body + timestamp |
| **Unread Indicator** | Blue Dot | Left side of unread notifications |
| **Empty State** | Illustration | "No notifications yet" + "We'll let you know when vendors are nearby" |

### 2.3 Notification Card Structure
| Element | Description |
|---------|-------------|
| **Icon** | Type-specific: 📍 nearby, ✅ accepted, ❌ rejected, 🎉 fulfilled, ⏰ expired, 🚚 upcoming |
| **Title** | "Vendor is Nearby!" |
| **Body** | "A vendor is 85m away from you. Get ready!" |
| **Timestamp** | "2 min ago" / "Today 10:30 AM" |
| **Tap Action** | Deep link to relevant screen (order details, map, etc.) |

---

## 3. Notification Types

| Type | Icon | Title | Body | Tap Action |
|------|------|-------|------|------------|
| `vendor_nearby` | 📍 | "Vendor is Nearby!" | "{distance}m away from you" | Open Live Tracking |
| `order_accepted` | ✅ | "Order Accepted!" | "Your order has been accepted by the vendor" | Open Order Details |
| `order_rejected` | ❌ | "Order Declined" | "The vendor could not accept your order" | Open Orders |
| `order_fulfilled` | 🎉 | "Order Complete!" | "Your order has been fulfilled. Thank you!" | Open Order Details |
| `order_expired` | ⏰ | "Order Expired" | "The vendor has passed your location" | Open Orders |
| `vendor_upcoming` | 🚚 | "Vendor Coming Your Way!" | "ETA: ~{minutes} minutes" | Open Live Tracking |

---

## 4. Design Pro Tips

### 📱 Notification Card
- **Background**: Unread → light tinted background (#F0F7FF). Read → white.
- **Icon size**: 40x40px colored circle with white emoji centered.
- **Typography**: Title: 15px semibold. Body: 13px regular, 2-line max. Time: 12px muted.
- **Swipe actions**: Swipe left to delete, swipe right to mark as read.
- **Grouped**: Group by day — "Today", "Yesterday", "This Week".

### 🔔 Push Notification Design (OS-Level)
- **Rich notifications**: On Android, use BigTextStyle. On iOS, use rich notification extensions.
- **Action buttons**: "View Order" / "Track on Map" — inline in the notification.
- **Silent notifications**: `vendor_location_update` should NOT show OS notifications — only update the app's internal state.
- **Sound**: Use a custom short sound for `vendor_nearby` (distinct from default).

### 🎬 Animations
- **New notification**: Slide in from top with bounce.
- **Mark as read**: Fade out the blue dot indicator.
- **Delete**: Slide left + shrink + fade.

---

## 5. Backend Integration

### 5.1 FCM Push Notifications (Server → Client)

All notifications are sent via Firebase Cloud Messaging:

```json
{
  "notification": {
    "title": "📍 Vendor is Nearby!",
    "body": "A vendor is 85m away from you. Get ready!"
  },
  "data": {
    "type": "vendor_nearby",
    "vendor_id": "1",
    "distance": "85",
    "action": "open_map"
  }
}
```

### 5.2 FCM Token Registration

| Property | Value |
|----------|-------|
| **Endpoint** | `POST /users/fcm-token` |
| **Auth Required** | ✅ Yes |

**Request:** `{ "token": "fcm_device_token" }`

### 5.3 Socket.IO Events (Real-Time)

| Event | From | Notification Created |
|-------|------|---------------------|
| `vendor_nearby` | proximity.js | Yes — FCM + socket |
| `order_update` | order.service.js | Yes — FCM + socket |
| `order_expired` | proximity.js | Yes — FCM + socket |

### 5.4 Local Storage

Notifications should be stored **locally** on the device (SQLite / SharedPreferences) for offline access. The backend does NOT store a notification history — it's fire-and-forget.

---

## 6. Analytics Events

| Event Name | Trigger | Properties |
|------------|---------|------------|
| `screen_view_notifications` | Screen opens | `{ unread_count }` |
| `notification_tapped` | Card tapped | `{ type, notification_id }` |
| `notifications_mark_all_read` | Mark all tapped | `{ count }` |
| `notification_deleted` | Swiped to delete | `{ type }` |

---

*Previous: [← Live Tracking](./07_live_tracking_page.md) | Next: [Orders/History →](./09_orders_history_page.md)*
