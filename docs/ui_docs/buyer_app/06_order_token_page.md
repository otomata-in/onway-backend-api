# 🎟️ Buyer App — Order Token Page

> Page ID: `BUYER-06` | Priority: **P0 (Critical)** | Type: **Transaction**

---

## 1. Screen Overview

The Order Token Page is where the buyer **confirms their intent** to buy. Unlike a traditional checkout, this is an **intent-based token** — not a guaranteed order. The vendor can accept or reject it. This distinction must be clearly communicated in the UI to set correct expectations.

---

## 2. UI Elements & Layout

### 2.1 Header
| Element | Type | Description |
|---------|------|-------------|
| **Back Arrow** | Icon Button | Returns to Vendor Details |
| **Title** | Text | "Confirm Your Order Token" |

### 2.2 Intent Banner
| Element | Type | Description |
|---------|------|-------------|
| **Info Banner** | Card | 💡 "This is an intent — not a confirmed order. The vendor will accept or decline based on availability." |

### 2.3 Vendor Info (Summary)
| Element | Type | Description |
|---------|------|-------------|
| **Vendor Name** | Text | "Fresh Fish Van" |
| **Distance** | Badge | "0.5 km" |
| **ETA** | Badge | "~2 min" |

### 2.4 Selected Items List
| Element | Type | Description |
|---------|------|-------------|
| **Item Row** | List Item | Item name, price per unit, quantity stepper, subtotal |
| **Quantity Stepper** | `[-  2  +]` | Modify quantity inline |
| **Remove Button** | X icon | Remove item from token |
| **Item Subtotal** | Right-aligned | "₹900" (price × qty) |

### 2.5 Price Summary
| Element | Type | Description |
|---------|------|-------------|
| **Items Total** | Row | "3 items" — "₹1,350" |
| **Disclaimer** | Small Text | "Final price may vary based on actual weight/quantity" |

### 2.6 Location Section
| Element | Type | Description |
|---------|------|-------------|
| **Your Location** | Map Pin + Text | "📍 Kaloor, Kochi" |
| **Change Location** | Text Link | "Change" — opens location picker |
| **Mini Map** | Small Map | Shows buyer's pin location |

### 2.7 Confirm CTA
| Element | Type | Description |
|---------|------|-------------|
| **Confirm Button** | Primary CTA | "🎟️ Send Order Token" — full width |
| **Cancel Link** | Text Button | "Cancel" — below the button |

---

## 3. UI States

| State | Description |
|-------|-------------|
| **Review** | Items listed, modifiable, button ready |
| **Empty Cart** | All items removed → "No items selected" + back button |
| **Submitting** | Button shows spinner, all inputs disabled |
| **Success** | Success animation → auto-navigate to Live Tracking |
| **Error** | Error toast: "Failed to send token. Vendor may be offline" |
| **Vendor Inactive** | "⚠️ Vendor is currently offline" error — block submission |
| **Invalid Items** | "Some items are no longer available" — highlight invalid items |

---

## 4. Design Pro Tips

### 💡 Intent Communication
- **Critical UX decision**: Make the "intent vs order" distinction VERY clear. Use an info banner, NOT small print.
- **Banner design**: Light yellow background (#FFF8E1), left-side icon (💡), slightly rounded, 12px border-radius.
- **Language**: Use phrases like "order token" and "intent to buy" consistently. Never say "checkout" or "purchase".
- **Expectation text**: "The vendor will notify you when they accept"

### 🛒 Item List
- **Editable**: Allow quantity changes right on this page (don't force back to vendor details).
- **Price formatting**: Always show currency symbol (₹) + decimal for consistency. `₹450.00`
- **Remove action**: Swipe-to-remove on mobile. X icon on desktop. Confirm dialog for last item.
- **Item images**: If available in future, show small thumbnails (40x40px) left of item name.

### 📍 Location Section
- **Auto-detect**: Pre-fill with user's current GPS location.
- **Editable**: Let users pin a different location (e.g., their home) — critical for "I'm at work but want the vendor near home."
- **Location display**: Show human-readable address, not coordinates.
- **Map size**: Small inline map (~120px height), non-interactive. Just shows the pin.

### 🎬 Animations
- **Quantity change**: Counter roll animation.
- **Item remove**: Slide left + fade out.
- **Submit**: Button → spinner → checkmark animation → screen transition.
- **Price total**: Animate number change when quantities update.

### ⚠️ Error Prevention
- **Validate vendor is still active** before showing submit button.
- **Re-validate items** when the page loads (vendor may have toggled availability).
- **Disable submit** if vendor goes offline while user is on this page (socket event).
- **Prevent double-submit**: Disable button immediately on tap.

---

## 5. Backend API Integration

### 5.1 Create Order Token

| Property | Value |
|----------|-------|
| **Endpoint** | `POST /orders` |
| **Auth Required** | ✅ Yes (Bearer token) |
| **Method** | POST |

**Request Body:**
```json
{
  "vendor_id": 2,
  "buyer_lat": 10.12,
  "buyer_lng": 76.34,
  "items": [
    { "item_id": 1, "qty": 2 },
    { "item_id": 3, "qty": 1 }
  ]
}
```

**Success Response (201):**
```json
{
  "success": true,
  "data": {
    "id": 15,
    "buyer_id": 1,
    "vendor_id": 2,
    "status": "requested",
    "type": "token",
    "buyer_lat": 10.12,
    "buyer_lng": 76.34,
    "orderItems": [
      {
        "id": 1,
        "qty": 2,
        "item": { "id": 1, "name": "King Fish", "price": 450.00 }
      },
      {
        "id": 2,
        "qty": 1,
        "item": { "id": 3, "name": "Prawns", "price": 550.00 }
      }
    ]
  }
}
```

**Server-Side Actions on Create:**
1. Validates vendor exists and is active
2. Validates all items belong to vendor and are available
3. Prevents self-ordering
4. Creates order + order_items in DB transaction
5. Emits `new_order` socket event to vendor
6. Sends FCM push notification to vendor

### 5.2 Error Responses

| Status | Code | Message | UI Action |
|--------|------|---------|-----------|
| 400 | `VENDOR_INACTIVE` | "Vendor is currently not selling" | Show offline banner |
| 400 | `SELF_ORDER` | "You cannot place an order with yourself" | Show error toast |
| 400 | `INVALID_ITEMS` | "One or more items are unavailable" | Highlight invalid items |
| 404 | `VENDOR_NOT_FOUND` | "Vendor not found" | Navigate back |
| 500 | `INTERNAL_ERROR` | "Failed to create order" | Show retry option |

---

## 6. Post-Submission Flow

```
Order Token Created
    │
    ├── Server emits 'new_order' to vendor via Socket.IO
    ├── Server sends FCM push to vendor
    │
    ▼
Buyer redirected to Orders/History Page (BUYER-09)
    │
    ├── Order shows as "Requested" (⏳ Pending)
    │
    ▼
Wait for vendor response:
    ├── 'order_update' socket event → status changes
    │   ├── "accepted" → Show ✅ notification
    │   ├── "rejected" → Show ❌ notification
    │   └── "fulfilled" → Show 🎉 notification
    │
    └── 'vendor_nearby' socket event → proximity alert
```

---

## 7. Analytics Events

| Event Name | Trigger | Properties |
|------------|---------|------------|
| `screen_view_order_token` | Screen opens | `{ vendor_id, item_count }` |
| `token_item_qty_changed` | Quantity modified | `{ item_id, new_qty }` |
| `token_item_removed` | Item removed | `{ item_id }` |
| `token_location_changed` | Location updated | — |
| `token_submitted` | Confirm button tapped | `{ vendor_id, item_count, est_total }` |
| `token_submit_success` | 201 response | `{ order_id }` |
| `token_submit_failed` | Error response | `{ error_code }` |

---

*Previous: [← Vendor Details](./05_vendor_details_page.md) | Next: [Live Tracking →](./07_live_tracking_page.md)*
