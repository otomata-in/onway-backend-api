# 📦 Buyer App — Orders / History Page

> Page ID: `BUYER-09` | Priority: **P0 (Critical)** | Type: **Order Management**

---

## 1. Screen Overview

The Orders page shows the buyer's **active order tokens** and **past order history**. It's organized into tabs — "Active" for in-progress tokens and "History" for completed/expired/rejected ones. Users should be able to track order status, view details, and potentially reorder from here.

---

## 2. UI Elements & Layout

### 2.1 Header
| Element | Type | Description |
|---------|------|-------------|
| **Title** | Text | "My Orders" |
| **Tab Bar** | Segmented | "Active" / "History" |

### 2.2 Active Orders Tab
| Element | Type | Description |
|---------|------|-------------|
| **Order Card** | List Item | Vendor name, items summary, status badge, timestamp |
| **Status Badge** | Colored Chip | ⏳ "Requested" (yellow) / ✅ "Accepted" (green) |
| **Track Button** | Secondary CTA | "Track Vendor →" — opens Live Tracking |
| **Empty State** | Illustration | "No active orders" + "Browse vendors to place one" |

### 2.3 History Tab
| Element | Type | Description |
|---------|------|-------------|
| **Order Card** | List Item | Same structure, but with final status |
| **Status Badge** | Colored Chip | 🎉 "Fulfilled" (green) / ❌ "Rejected" (red) / ⏰ "Expired" (gray) |
| **Reorder Button** | Text Button | "Order Again" — creates new token with same items/vendor |
| **Pagination** | Load More | "Load more" button or infinite scroll |

### 2.4 Order Card Detail
| Element | Type | Description |
|---------|------|-------------|
| **Vendor Name** | Title | "Fresh Fish Van" |
| **Items Summary** | Subtitle | "King Fish x2, Prawns x1" |
| **Total Estimate** | Text | "~₹1,450" |
| **Status** | Badge | Current order status |
| **Timestamp** | Small Text | "Today, 10:30 AM" |
| **Tap Action** | Navigation | Opens Order Detail View |

---

## 3. Order Detail View (Expanded)

When a card is tapped:

| Element | Description |
|---------|-------------|
| **Order ID** | "#ORD-15" |
| **Vendor Info** | Name + contact (mobile masked) |
| **Full Item List** | Each item with name, qty, price |
| **Price Breakdown** | Item subtotals + estimated total |
| **Status Timeline** | Visual timeline: Requested → Accepted → Fulfilled |
| **Buyer Location** | Map pin where the order was placed from |
| **Actions** | "Track Vendor" (if active), "Order Again" (if historical) |

---

## 4. Design Pro Tips

### 📋 Order Card Design
- **Card layout**: Compact — vendor icon left, text center, status badge right.
- **Status color system**: 
  - ⏳ Requested: `#FFA726` (amber)
  - ✅ Accepted: `#66BB6A` (green)
  - 🎉 Fulfilled: `#43A047` (dark green)
  - ❌ Rejected: `#EF5350` (red)
  - ⏰ Expired: `#9E9E9E` (gray)
- **Card elevation**: Active orders get higher elevation (more shadow) than history.
- **Active pulse**: Active order cards have a subtle left-border pulse animation.

### ⏱️ Status Timeline
- **Visual timeline**: Vertical dots connected by lines. Completed steps: filled green circles. Current step: pulsing. Future steps: empty gray circles.
- **Include timestamps**: "Requested at 10:30 AM" / "Accepted at 10:32 AM".
- **Expandable**: Collapsed by default on the card. Expanded in detail view.

### 🔄 Real-Time Updates
- **Listen for `order_update` socket events** on this page.
- **Auto-move cards**: When an active order gets fulfilled/rejected/expired, animate it moving from "Active" to "History" tab.
- **Badge update**: Show badge on "Active" tab with count of pending orders.

### 📦 Reorder Feature
- **Quick reorder**: "Order Again" button creates a new token with the same vendor + items.
- **Validation**: Check if vendor is still active AND items are still available before reordering.
- **If items changed**: Show "Some items are no longer available" and let user modify.

### 📄 Pagination
- **Page size**: 20 orders per page.
- **Infinite scroll**: Preferred over "Load More" button for smoother UX.
- **Loading indicator**: Shimmer cards at bottom while loading next page.

---

## 5. Backend API Integration

### 5.1 Get Buyer Orders

| Property | Value |
|----------|-------|
| **Endpoint** | `GET /orders?page={page}&limit={limit}&status={status}` |
| **Auth Required** | ✅ Yes (Bearer token) |

**Query Parameters:**
| Param | Type | Default | Description |
|-------|------|---------|-------------|
| `page` | int | 1 | Page number |
| `limit` | int | 20 | Items per page |
| `status` | string | — | Filter: "requested", "accepted", "fulfilled", "rejected", "expired" |

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
        "type": "token",
        "buyer_lat": 10.12,
        "buyer_lng": 76.34,
        "created_at": "2026-07-04T10:30:00Z",
        "vendor": {
          "id": 2,
          "user": { "mobile": "9876543210" }
        },
        "orderItems": [
          {
            "id": 1,
            "qty": 2,
            "item": { "id": 1, "name": "King Fish", "price": 450.00 }
          }
        ]
      }
    ],
    "total": 45,
    "page": 1,
    "limit": 20
  }
}
```

### 5.2 Get Order Details

| Property | Value |
|----------|-------|
| **Endpoint** | `GET /orders/:id` |
| **Auth Required** | ✅ Yes |

**Note:** Includes deleted items (unscoped) — so order history always shows what was ordered, even if vendor removed the item.

### 5.3 Active Orders Data Strategy

```
For "Active" tab:
  GET /orders?status=requested  +  GET /orders?status=accepted
  (merge results, sort by created_at DESC)

For "History" tab:
  GET /orders?status=fulfilled  (page 1)
  + GET /orders?status=rejected
  + GET /orders?status=expired
  (merge + paginate client-side, or make separate paginated calls)
```

### 5.4 Socket Events (Real-Time Status Updates)

| Event | Action |
|-------|--------|
| `order_update` | Update order status badge. Move card between tabs if status changes to terminal |
| `vendor_nearby` | Show "Vendor is nearby!" banner on the active order card |
| `order_expired` | Move order to History tab with "Expired" status |

---

## 6. Analytics Events

| Event Name | Trigger | Properties |
|------------|---------|------------|
| `screen_view_orders` | Screen opens | `{ active_count, history_count }` |
| `tab_switched` | Tab changed | `{ tab: "active" or "history" }` |
| `order_card_tapped` | Card tapped | `{ order_id, status }` |
| `reorder_tapped` | "Order Again" | `{ order_id, vendor_id }` |
| `track_vendor_tapped` | "Track Vendor" | `{ order_id, vendor_id }` |

---

*Previous: [← Notifications](./08_notifications.md) | Next: [Profile/Settings →](./10_profile_settings.md)*
