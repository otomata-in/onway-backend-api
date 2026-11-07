# 📦 Seller App — Orders Page

> Page ID: `SELLER-08` | Priority: **P0 (Critical)** | Type: **Order Management**

---

## 1. Screen Overview

The Seller Orders Page shows all incoming order tokens, allowing the vendor to **accept, reject, or fulfill** them. This is the core transactional screen — every order token from a buyer arrives here. It should feel like a **real-time order queue** — new orders appear instantly via Socket.IO.

---

## 2. UI Elements & Layout

### 2.1 Header
| Element | Type | Description |
|---------|------|-------------|
| **Back Arrow** | Icon Button | Returns to Dashboard |
| **Title** | Text | "Orders" |
| **Filter Tabs** | Segmented | "Pending" / "Accepted" / "All" |

### 2.2 Order Card (Incoming — Status: Requested)
| Element | Type | Description |
|---------|------|-------------|
| **Order ID** | Badge | "#ORD-15" |
| **Buyer Info** | Text | "Buyer: 98***43210" (masked mobile) |
| **Buyer Distance** | Badge | "450m away" — real-time |
| **Items List** | Compact List | "King Fish x2, Prawns x1" |
| **Estimated Total** | Text | "~₹1,450" |
| **Order Time** | Timestamp | "2 min ago" |
| **Accept Button** | Primary CTA | "✅ Accept" — green |
| **Reject Button** | Secondary CTA | "❌ Reject" — red outline |

### 2.3 Order Card (Accepted — Status: Accepted)
| Element | Type | Description |
|---------|------|-------------|
| **Same as above** | — | Plus additional elements below |
| **Buyer Direction** | Compass | Arrow pointing towards buyer location |
| **Buyer Distance** | Live Badge | Real-time distance updating |
| **Fulfill Button** | Primary CTA | "🎉 Mark Fulfilled" — green |

### 2.4 Order Card (Completed — Status: Fulfilled/Rejected/Expired)
| Element | Type | Description |
|---------|------|-------------|
| **Status Badge** | Chip | 🎉 "Fulfilled" / ❌ "Rejected" / ⏰ "Expired" |
| **Completed Time** | Text | "Fulfilled at 10:45 AM" |
| **No actions** | — | Historical — read-only |

---

## 3. UI States

| State | Description |
|-------|-------------|
| **Loading** | Shimmer order cards |
| **Empty (Pending)** | "No pending orders" + "Orders will appear here when buyers send tokens" |
| **New Order (Real-time)** | Card slides in from top with notification sound + vibration |
| **Accepting** | Accept button → spinner → ✅ checkmark |
| **Rejecting** | Confirmation: "Reject this order?" → slide away |
| **Fulfilling** | "Mark as fulfilled?" → confetti animation |
| **Error** | "Failed to update order" → retry button |

---

## 4. Design Pro Tips

### 📦 Order Card Design
- **Priority visual**: Pending orders get a yellow/amber left-border and pulsing animation. Accepted get green. Completed get gray.
- **Card height**: Generous — 150-180px for action cards. Show all critical info without expansion.
- **Button sizing**: Accept/Reject buttons should be LARGE (48px height minimum). Vendors tap these while walking.
- **Action button spacing**: Minimum 16px gap between Accept and Reject to prevent mis-taps.
- **Swipe actions**: Swipe right to accept, swipe left to reject (power user shortcut).

### 🔔 Real-Time Order Arrival
- **New order animation**: Card drops from top with bounce + sound chime.
- **Vibration pattern**: Double vibration pulse for new orders.
- **Priority sorting**: Newest orders at top. OR sort by buyer distance (nearest first).
- **Auto-refresh**: This screen should NEVER need manual refresh — all updates via socket.

### 📍 Distance Integration
- **Buyer direction**: Show a compass arrow pointing towards the buyer's location from vendor's current position.
- **Color coding**: Green (<200m — almost there!), Yellow (200m–1km), Orange (>1km).
- **Live updates**: Distance recalculates on every vendor location update.

### 🎯 Fulfillment Flow
- **Three-tap completion**: Tap card → Tap "Mark Fulfilled" → Confirm → Done.
- **Confirmation dialog**: "Did you deliver to this buyer?" with "Yes, Fulfilled" and "Cancel".
- **After fulfillment**: Card slides to "Completed" section with celebration animation.

### 📱 Vendor Accessibility
- **Large tap targets**: All buttons minimum 48x48px.
- **High contrast text**: Even in sunlight (vendors are outdoors).
- **Audio cues**: Sound notification for new orders (even with screen on).
- **Offline handling**: If connection drops, queue accept/reject actions and sync when reconnected.

---

## 5. Backend API Integration

### 5.1 Get Seller Orders

| Property | Value |
|----------|-------|
| **Endpoint** | `GET /seller/orders?page={page}&limit={limit}&status={status}` |
| **Auth Required** | ✅ Yes (Seller role) |

**Query Parameters:**
| Param | Default | Options |
|-------|---------|---------|
| `status` | — | "requested", "accepted", "fulfilled", "rejected", "expired" |
| `page` | 1 | Pagination |
| `limit` | 20 | Items per page |

**Response:**
```json
{
  "success": true,
  "data": {
    "orders": [
      {
        "id": 15,
        "buyer_id": 1,
        "vendor_id": 2,
        "status": "requested",
        "buyer_lat": 10.12,
        "buyer_lng": 76.34,
        "created_at": "2026-07-04T10:30:00Z",
        "buyer": { "id": 1, "mobile": "9876543210" },
        "orderItems": [
          {
            "id": 1,
            "qty": 2,
            "item": { "id": 1, "name": "King Fish", "price": 450.00 }
          }
        ]
      }
    ],
    "total": 25,
    "page": 1,
    "limit": 20
  }
}
```

### 5.2 Accept Order

| Property | Value |
|----------|-------|
| **Endpoint** | `POST /orders/:id/accept` |
| **Auth Required** | ✅ Yes (Seller, order owner) |

**Validation:** Status must be "requested". Only vendor owner can accept.

**Server-side effects:**
1. Status: requested → accepted
2. Socket event `order_update` → buyer
3. FCM push "✅ Order Accepted!" → buyer

### 5.3 Reject Order

| Property | Value |
|----------|-------|
| **Endpoint** | `POST /orders/:id/reject` |
| **Auth Required** | ✅ Yes |

**Server-side effects:**
1. Status: requested → rejected
2. Socket + FCM "❌ Order Declined" → buyer

### 5.4 Fulfill Order

| Property | Value |
|----------|-------|
| **Endpoint** | `POST /orders/:id/fulfill` |
| **Auth Required** | ✅ Yes |

**Validation:** Status must be "accepted" (can't fulfill a requested order — must accept first).

**Server-side effects:**
1. Status: accepted → fulfilled
2. Socket + FCM "🎉 Order Complete!" → buyer

### 5.5 Socket Events (Real-Time)

| Event | Direction | Action |
|-------|-----------|--------|
| `new_order` | Server → Seller | Add new order card at top of list |

**Payload:**
```json
{
  "type": "new_order",
  "order": {
    "id": 16,
    "buyer_id": 3,
    "status": "requested",
    "items": [...]
  },
  "timestamp": "2026-07-04T10:45:00Z"
}
```

### 5.6 Error Responses

| Status | Code | UI Action |
|--------|------|-----------|
| 400 | `INVALID_STATUS_TRANSITION` | "Cannot accept an already accepted order" — toast |
| 403 | `FORBIDDEN` | "You don't own this order" — should not happen in normal flow |
| 404 | `ORDER_NOT_FOUND` | Remove card from list |

---

## 6. Order Status Flow

```
                    ┌─────────────┐
                    │  REQUESTED  │ ← New order arrives (socket)
                    │   ⏳ pending │
                    └──┬───────┬──┘
                       │       │
              Accept   │       │  Reject
                       ▼       ▼
              ┌────────────┐  ┌───────────┐
              │  ACCEPTED  │  │  REJECTED  │
              │   ✅ active │  │   ❌ done  │
              └──────┬─────┘  └───────────┘
                     │
              Fulfill │
                     ▼
              ┌────────────┐
              │  FULFILLED │
              │   🎉 done  │
              └────────────┘

Special:
  Proximity exit → EXPIRED (automatic, server-side)
```

---

## 7. Analytics Events

| Event Name | Trigger | Properties |
|------------|---------|------------|
| `screen_view_seller_orders` | Screen opens | `{ pending_count, accepted_count }` |
| `order_received` | New order socket | `{ order_id }` |
| `order_accepted` | Accept tapped | `{ order_id, response_time_seconds }` |
| `order_rejected` | Reject tapped | `{ order_id, response_time_seconds }` |
| `order_fulfilled` | Fulfill tapped | `{ order_id }` |

---

*Previous: [← Start Selling](./07_start_selling_mode.md) | Next: [Active Delivery Mode →](./09_active_delivery_mode.md)*
