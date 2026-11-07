# 🟢 Seller App — Start Selling Mode

> Page ID: `SELLER-07` | Priority: **P0 (Critical)** | Type: **Active Selling**

---

## 1. Screen Overview

When a vendor toggles "Start Selling" on the Dashboard, the app enters **Selling Mode**. This is a persistent state that runs a background GPS service, broadcasts location to buyers, and keeps the vendor visible on the map. The UI transforms into an active selling dashboard with real-time updates.

---

## 2. UI Elements & Layout

### 2.1 Status Bar
| Element | Type | Description |
|---------|------|-------------|
| **Persistent Banner** | Top Bar | "🟢 You're LIVE — Selling for 1h 23m" |
| **Stop Button** | Text Button | "Stop Selling" — in the banner |

### 2.2 Live Map
| Element | Type | Description |
|---------|------|-------------|
| **Map View** | Full Map | Vendor's current position with route overlay |
| **Self Marker** | Pulsing Icon | Vendor's own position (green pulsing dot) |
| **Route Polyline** | Colored Line | Active route with progress highlighting |
| **Buyer Markers** | Blue Dots | Nearby buyers who have placed order tokens |
| **Order Radius** | Circle | Buyer's proximity zones (100m rings around buyer locations) |

### 2.3 Active Orders Overlay
| Element | Type | Description |
|---------|------|-------------|
| **Order Pill** | Floating Card | "3 active orders" — tappable to expand |
| **Expanded List** | Bottom Sheet | Quick view of active orders with buyer locations |

### 2.4 GPS Status
| Element | Type | Description |
|---------|------|-------------|
| **GPS Indicator** | Icon | 📡 Green = good signal, Yellow = weak, Red = no signal |
| **Last Updated** | Small Text | "Location updated 2s ago" |

---

## 3. Design Pro Tips

### 🟢 Active Mode Visual Identity
- **Green everything**: When in selling mode, the app should feel distinctly "live" — green accent colors, pulsing elements, active animations.
- **Persistent notification**: Android requires a foreground service notification. Design a clean notification: "OnWay — You're selling now" with elapsed time.
- **Battery indicator**: Show battery level warning if below 20% — GPS drains battery fast.

### 🗺️ Selling Mode Map
- **Auto-center on vendor**: Map follows vendor's GPS updates. Re-centers automatically.
- **Route progress**: Show completed waypoints as green circles, upcoming as hollow circles.
- **Buyer proximity visualization**: Show semi-transparent rings around buyer locations (100m radius). When vendor enters a ring, it turns green.
- **Heading indicator**: Show vendor's direction of travel as a chevron/arrow on the marker.

### 📱 Background Service Requirements
- **GPS tracking**: Must continue even when app is backgrounded or screen is off.
- **Android**: Use `ForegroundService` with `LOCATION` type. Show persistent notification.
- **iOS**: Use `allowsBackgroundLocationUpdates` with `significantLocationChanges` or continuous background mode.
- **Battery optimization**: 
  - Active foreground: GPS every 3 seconds
  - App backgrounded: GPS every 10 seconds
  - Low battery (<15%): GPS every 30 seconds

---

## 4. Backend API Integration

### 4.1 Location Updates (Continuous)

| Property | Value |
|----------|-------|
| **Endpoint** | `POST /vendors/location` |
| **Auth Required** | ✅ Yes |
| **Frequency** | Every 3-5 seconds |

**Request:** `{ "lat": 10.012, "lng": 76.345 }`

**Server-side chain reaction:**
```
POST /vendors/location
    │
    ├── 1. Save to DB (vendor.lat, vendor.lng)
    ├── 2. Cache in Redis (vendor_location:{id}, TTL 1hr)
    ├── 3. Socket.IO broadcast: 'vendor_location_update'
    └── 4. Proximity check for ALL active orders
         │
         ├── Order within 100m? → 'vendor_nearby' event + FCM
         └── Order was within, now >120m? → Expire order + FCM
```

### 4.2 Toggle Status

| Endpoint | `POST /vendors/status` |
|----------|------------------------|
| **Request** | `{ "is_active": true }` (start) or `{ "is_active": false }` (stop) |

### 4.3 Socket Events (Incoming)

| Event | Action |
|-------|--------|
| `new_order` | Show toast + notification badge. Add buyer marker to map |

---

## 5. Analytics Events

| Event Name | Trigger | Properties |
|------------|---------|------------|
| `selling_mode_started` | Toggle on | — |
| `selling_mode_stopped` | Toggle off | `{ duration_minutes }` |
| `gps_signal_lost` | GPS unavailable | `{ duration_seconds }` |
| `low_battery_warning` | Battery <20% | `{ battery_level }` |

---

*Previous: [← Add/Edit Item](./06_add_edit_item.md) | Next: [Orders Page →](./08_orders_page.md)*
