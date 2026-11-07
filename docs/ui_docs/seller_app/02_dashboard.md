# 📊 Seller App — Dashboard

> Page ID: `SELLER-02` | Priority: **P0 (Critical)** | Type: **Home / Control Center**

---

## 1. Screen Overview

The Dashboard is the seller's **command center**. It shows at a glance: are they currently selling? how many orders do they have? what's their current route? It provides one-tap access to start/stop selling, view orders, and manage inventory. This screen should feel like a **cockpit** — everything the vendor needs is visible immediately.

---

## 2. UI Elements & Layout

### 2.1 Header
| Element | Type | Description |
|---------|------|-------------|
| **Welcome Text** | Title | "Welcome back, Vendor!" |
| **Notification Bell** | Icon | Unread notification count |
| **Profile Avatar** | Circle | Tappable → Profile/Settings |

### 2.2 Selling Status Toggle (HERO ELEMENT)
| Element | Type | Description |
|---------|------|-------------|
| **Status Card** | Large Card | Centered, prominent — the most important element |
| **Toggle Switch** | Large Toggle | "Start Selling" / "Stop Selling" |
| **Status Label** | Text | 🟢 "You're LIVE" (green) / 🔴 "You're OFFLINE" (red) |
| **Active Duration** | Subtitle | "Selling for 2h 15m" (timer since toggle on) |

### 2.3 Stats Grid
| Element | Type | Description |
|---------|------|-------------|
| **Today's Orders** | Stat Card | Number + label: "12 orders today" |
| **Active Orders** | Stat Card | Pending/accepted count: "3 active" (tappable) |
| **Fulfilled Today** | Stat Card | Completed count: "9 fulfilled" |
| **Total Items** | Stat Card | Item count: "15 items listed" |

### 2.4 Quick Actions
| Element | Type | Description |
|---------|------|-------------|
| **View Orders** | Action Card | "📦 Orders" → Opens Orders Page |
| **Manage Items** | Action Card | "📋 Inventory" → Opens Inventory Page |
| **Setup Route** | Action Card | "🗺️ Routes" → Opens Route Management |
| **Active Route** | Info Card | Currently active route name (if any) |

### 2.5 Active Route Preview (if route is active)
| Element | Type | Description |
|---------|------|-------------|
| **Route Name** | Text | "Morning Route - Kaloor" |
| **Progress** | Progress Bar | "Waypoint 3/7" |
| **Mini Map** | Small Map | Shows route + current position |

---

## 3. UI States

| State | Description |
|-------|-------------|
| **Offline (Default)** | Red status card, stats from today visible, "Start Selling" button |
| **Going Live** | Toggle animation, GPS initializing: "Getting your location..." |
| **Live / Selling** | Green status card, pulsing "LIVE" indicator, timer running |
| **Going Offline** | Confirmation dialog: "Stop selling? Active orders will remain" |
| **No Items** | Warning: "⚠️ Add items before you start selling" |
| **No Route** | Suggestion: "Set up a route for better visibility" |
| **Error** | "Failed to update status" — retry button |

---

## 4. Design Pro Tips

### 🎛️ Status Toggle (Critical Element)
- **Size**: Make it BIG. This is the primary action — minimum 80px tall card.
- **Color transition**: Animate background from red → green when toggling on. Use a 500ms ease-in-out transition.
- **Haptic feedback**: Vibrate on toggle (medium intensity).
- **Confirmation on stop**: "Are you sure? You have 3 active orders" — require confirmation to stop.
- **GPS indicator**: When going live, show a "📡 Getting GPS..." message with a location icon pulse.

### 📊 Stats Cards
- **Grid layout**: 2x2 grid of stat cards.
- **Card size**: Each card ~160x100px.
- **Number emphasis**: The number should be 28-32px bold. The label: 12px muted below.
- **Color coding**: Active orders in amber (needs attention), fulfilled in green (positive).
- **Tap action**: Each stat card should be tappable — navigates to relevant detail view.
- **Counter animation**: Numbers should count up on load (0 → 12 over 500ms).

### 🗺️ Active Route
- **Show route card ONLY when a route is active** — don't show an empty card.
- **Progress bar**: Segmented bar showing waypoint progress. Current segment highlighted.
- **Mini map**: 120px height, non-interactive. Route polyline + current position dot.
- **Route name**: Truncate with "..." if too long.

### 🎯 Quick Actions
- **Large tap targets**: Each action card should be at minimum 80px tall.
- **Icons**: Use filled, colored icons (not outlined) — feels more actionable.
- **Badge counts**: Show unread/pending counts on "Orders" (e.g., "📦 Orders ③").
- **Notification dot**: Red dot on orders card if there are new incoming orders.

### 📱 Mobile-First Design
- **Vendor persona**: These are **street vendors** — possibly with low tech literacy.
- **Large text**: Minimum 16px body text, 14px minimum for secondary text.
- **Simple language**: "Start Selling" not "Toggle Active Status". "Your Items" not "Inventory Management".
- **One-hand operation**: All CTAs in the lower 2/3 of the screen (thumb zone).
- **Minimal navigation depth**: Maximum 2 taps to any function.

### ⚡ Performance
- **Dashboard data should load in < 1.5s** — it's the landing page.
- **Cache stats**: Show cached stats immediately, refresh in background.
- **Socket reconnect**: Re-establish socket connection on dashboard mount if disconnected.

---

## 5. Backend API Integration

### 5.1 Get Dashboard Data

| Property | Value |
|----------|-------|
| **Endpoint** | `GET /seller/dashboard` |
| **Auth Required** | ✅ Yes (Seller role required) |

**Response:**
```json
{
  "success": true,
  "data": {
    "vendor": {
      "id": 1,
      "is_active": true,
      "lat": 10.012,
      "lng": 76.345
    },
    "stats": {
      "total_orders_today": 12,
      "active_orders": 3,
      "fulfilled_today": 9,
      "total_items": 15
    }
  }
}
```

### 5.2 Toggle Selling Status

| Property | Value |
|----------|-------|
| **Endpoint** | `POST /vendors/status` |
| **Auth Required** | ✅ Yes (Seller role) |

**Request:**
```json
{ "is_active": true }
```

**Response:**
```json
{
  "success": true,
  "data": { "id": 1, "is_active": true }
}
```

**Server-side effects when going LIVE:**
- Vendor becomes visible on the buyer app map
- Location tracking begins (frontend starts sending GPS updates)
- Socket channel established for receiving orders

**Server-side effects when going OFFLINE:**
- Vendor hidden from buyer discovery
- Active orders remain until fulfilled/expired
- Location data stops updating

### 5.3 Update Vendor Location

| Property | Value |
|----------|-------|
| **Endpoint** | `POST /vendors/location` |
| **Auth Required** | ✅ Yes (Seller role) |

**Request:** `{ "lat": 10.012, "lng": 76.345 }`

**Server-side effects:**
1. Updates vendor lat/lng in DB
2. Caches location in Redis (TTL 1hr)
3. Broadcasts `vendor_location_update` via Socket.IO to all buyers
4. Runs proximity check for all active orders (enter/exit zone detection)

**Frontend should call this:**
- Every 3-5 seconds when selling is active
- Use GPS background service for continuous tracking
- Send via REST (not socket) for reliability

### 5.4 Get Active Route

| Property | Value |
|----------|-------|
| **Endpoint** | `GET /seller/routes/active` |
| **Auth Required** | ✅ Yes (Seller role) |

### 5.5 Socket Events (Incoming)

| Event | Action |
|-------|--------|
| `new_order` | Show notification badge + toast: "New order received!" |

---

## 6. Location Tracking Service (Background)

When selling is active, the app must run a **background GPS service**:

```
┌─────────────────────────────┐
│ GPS Service (every 3-5 sec) │
└──────────┬──────────────────┘
           │
           ▼
    POST /vendors/location
           │
           ├── DB: update vendor lat/lng
           ├── Redis: cache location (TTL 1hr)
           ├── Socket: broadcast to all buyers
           └── Proximity: check active orders
```

**Battery optimization tips:**
- Use `requestLocationUpdates` with balanced priority
- Batch location writes (accumulate 2-3 points, send together)
- Switch to passive location when app is backgrounded for >5 minutes
- Show persistent notification: "OnWay — You're selling" (Android foreground service requirement)

---

## 7. Analytics Events

| Event Name | Trigger | Properties |
|------------|---------|------------|
| `screen_view_dashboard` | Screen opens | `{ is_active, order_count }` |
| `selling_toggled` | Status changed | `{ is_active, active_orders }` |
| `quick_action_tapped` | Action card tapped | `{ action: "orders"/"inventory"/"routes" }` |
| `new_order_received` | Socket event | `{ order_id }` |

---

*Previous: [← Login](./01_login_screen.md) | Next: [Route Setup →](./03_route_setup.md)*
