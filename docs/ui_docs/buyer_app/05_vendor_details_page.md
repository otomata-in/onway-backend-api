# 🏪 Buyer App — Vendor Details Page

> Page ID: `BUYER-05` | Priority: **P0 (Critical)** | Type: **Product Discovery**

---

## 1. Screen Overview

The Vendor Details Page shows everything about a specific vendor — their live location, item catalog, prices, availability, and a CTA to place an order token. This is the **decision-making screen** — the user decides here whether to place an intent.

---

## 2. UI Elements & Layout

### 2.1 Header
| Element | Type | Description |
|---------|------|-------------|
| **Back Arrow** | Icon Button | Returns to Home / Vendor List |
| **Vendor Name** | Title | "Fresh Fish Van" — large, bold |
| **Favorite Button** | Heart Icon | ♡ / ♥ toggle |
| **Share Button** | Icon | Share vendor link (future) |

### 2.2 Vendor Info Card
| Element | Type | Description |
|---------|------|-------------|
| **Category Badge** | Colored Pill | "🐟 Fresh Fish" |
| **Status Indicator** | Live Dot | 🟢 "Currently Selling" / 🔴 "Offline" |
| **Distance** | Text | "0.5 km away" |
| **ETA** | Text | "~2 minutes" |
| **Mini Map** | Embedded Map | Small map showing vendor's current position + route (if active) |
| **Route Badge** | Info Chip | "📍 On Route: Market → Kaloor → Edappally" (if route is active) |
| **Track Button** | Secondary CTA | "Track on Map" — opens Live Tracking (BUYER-07) |

### 2.3 Items Section
| Element | Type | Description |
|---------|------|-------------|
| **Section Title** | Text | "Available Items" with count: "(12 items)" |
| **Item Cards** | List | Each item as a row card |

### 2.4 Individual Item Card
| Element | Type | Description |
|---------|------|-------------|
| **Item Name** | Title | "King Fish (Ayakura)" |
| **Price** | Bold Text | "₹450 /kg" |
| **Availability** | Badge | 🟢 "Available" / 🔴 "Sold Out" |
| **Quantity Available** | Subtitle | "5 kg remaining" |
| **Add Button** | + Button | Add to order token (opens quantity picker) |

### 2.5 Bottom CTA
| Element | Type | Description |
|---------|------|-------------|
| **Order Summary Bar** | Sticky Bottom Bar | Shows item count + estimated total |
| **Place Token Button** | Primary CTA | "Place Order Token (3 items)" — navigates to Order Token Page |

---

## 3. UI States

| State | Description |
|-------|-------------|
| **Loading** | Skeleton UI for vendor info + shimmer item list |
| **Loaded** | Full vendor info + items displayed |
| **Vendor Offline** | Dimmed UI, "Vendor is currently offline" banner, items still visible |
| **No Items** | Empty items section: "This vendor hasn't added items yet" |
| **All Sold Out** | Items visible but greyed, "All items sold out" banner |
| **Items Selected** | Bottom bar appears with item count + total |
| **Error** | "Failed to load vendor" with retry button |

---

## 4. Design Pro Tips

### 🎨 Vendor Info Card
- **Gradient background**: Subtle gradient matching the category color (blue-tinted for fish, green-tinted for vegetables).
- **Mini map**: 150px height, non-interactive. Show vendor marker + route polyline if available.
- **Animated status dot**: For "Currently Selling" — use a pulsing CSS animation.
- **Route display**: Show route as a dotted path with waypoint markers. Highlight the "current segment" in bold.

### 🛒 Item List Design
- **Grid vs List**: Use a **list layout** (not grid) — items have price + quantity, which needs horizontal space.
- **Price typography**: Use a bold, slightly larger font for price. Right-aligned.
- **Availability coding**: Green text for available, red strikethrough for sold out.
- **Add button**: Circular `+` button (40x40px). When tapped, expands into a quantity stepper `[-  2  +]`.
- **Quantity stepper**: Horizontal, inline. `-` button, number, `+` button. Minimum: 1, Maximum: available qty.
- **Out-of-stock items**: Show at the bottom, greyed out. Don't hide them — users should see the full catalog.

### 📊 Bottom Order Bar
- **Slide-up animation**: When first item is added, the bar slides up from bottom.
- **Sticky**: Always visible at screen bottom when items are selected.
- **Content**: "🛒 3 items | ₹1,350" — left side. "Place Token →" button — right side.
- **Dismiss**: Swipe down or tap X to clear selection (with confirmation).

### 🔄 Real-Time Updates
- **Listen for vendor location updates** — update distance/ETA live.
- **Item availability**: Poll every 30 seconds OR use socket events for stock changes.
- **Vendor goes offline while viewing**: Show a toast "Vendor is now offline" + dim the screen.

### 🎬 Animations
- **Screen entry**: Slide from right (standard navigation).
- **Item add**: Scale-up bounce on the `+` button + particle effect.
- **Bottom bar appear**: Slide up with spring physics.
- **Quantity change**: Number counter animation (roll up/down).

---

## 5. Backend API Integration

### 5.1 Get Vendor Details

| Property | Value |
|----------|-------|
| **Endpoint** | `GET /vendors/:id` |
| **Auth Required** | ✅ Yes |

**Response:**
```json
{
  "success": true,
  "data": {
    "id": 1,
    "is_active": true,
    "lat": 10.0123,
    "lng": 76.3456,
    "created_at": "2026-01-15T10:30:00Z",
    "user": {
      "id": 5,
      "mobile": "9876543210"
    }
  }
}
```

### 5.2 Get Vendor Items

| Property | Value |
|----------|-------|
| **Endpoint** | `GET /vendors/:id/items` |
| **Auth Required** | ✅ Yes |

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "name": "King Fish",
      "price": 450.00,
      "quantity": 5,
      "is_available": true
    },
    {
      "id": 2,
      "name": "Prawns",
      "price": 550.00,
      "quantity": 0,
      "is_available": false
    }
  ]
}
```

### 5.3 Get Vendor Route (for map display)

| Property | Value |
|----------|-------|
| **Endpoint** | `GET /vendors/:id/route` |
| **Auth Required** | ✅ Yes |

**Response:**
```json
{
  "success": true,
  "data": {
    "id": 3,
    "name": "Morning Route - Kaloor",
    "is_active": true,
    "current_route_index": 2,
    "points": [
      { "id": 1, "lat": 10.01, "lng": 76.30, "sequence": 1 },
      { "id": 2, "lat": 10.02, "lng": 76.31, "sequence": 2 },
      { "id": 3, "lat": 10.03, "lng": 76.32, "sequence": 3 }
    ]
  }
}
```

**Note:** `current_route_index` tells which waypoint the vendor has reached. Use this to draw the "completed" vs "remaining" route on the mini map.

### 5.4 Get Vendor ETA

| Property | Value |
|----------|-------|
| **Endpoint** | `GET /vendors/:id/eta?lat={lat}&lng={lng}` |
| **Auth Required** | ✅ Yes |

### 5.5 Toggle Favorite

| Property | Value |
|----------|-------|
| **Endpoint** | `POST /vendors/:id/favorite` |
| **Auth Required** | ✅ Yes |

---

## 6. Data Assembly

```
Screen Mount
    │
    ├── GET /vendors/:id         → Vendor info + status
    ├── GET /vendors/:id/items   → Item catalog
    ├── GET /vendors/:id/route   → Route for mini map (if active)
    └── GET /vendors/:id/eta     → ETA calculation
    
All 4 calls in parallel → assemble screen data
```

---

## 7. Analytics Events

| Event Name | Trigger | Properties |
|------------|---------|------------|
| `screen_view_vendor_details` | Screen opens | `{ vendor_id }` |
| `item_added_to_token` | + button tapped | `{ item_id, qty }` |
| `item_removed_from_token` | Qty reduced to 0 | `{ item_id }` |
| `track_on_map_tapped` | Track button tapped | `{ vendor_id }` |
| `place_token_initiated` | Bottom CTA tapped | `{ vendor_id, item_count, est_total }` |

---

*Previous: [← Vendor List](./04_vendor_list_view.md) | Next: [Order Token Page →](./06_order_token_page.md)*
