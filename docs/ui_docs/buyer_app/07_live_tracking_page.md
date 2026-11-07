# 📡 Buyer App — Live Tracking Page

> Page ID: `BUYER-07` | Priority: **P0 (Critical)** | Type: **Real-Time Experience**

---

## 1. Screen Overview

The Live Tracking Page lets the buyer watch a vendor's real-time movement on a map. It shows the vendor's current position, their route (if available), and the estimated time of arrival. This is the **most technically complex UI screen** in the entire app — it relies entirely on Socket.IO for real-time updates.

---

## 2. UI Elements & Layout

### 2.1 Header
| Element | Type | Description |
|---------|------|-------------|
| **Back Arrow** | Icon Button | Returns to previous screen |
| **Title** | Text | "Tracking Fish Van" |
| **Status Chip** | Badge | "🟢 Live" or "🟡 Last seen 2 min ago" |

### 2.2 Full-Screen Map
| Element | Type | Description |
|---------|------|-------------|
| **Map** | Full-screen interactive | Background — vendor + buyer markers |
| **Vendor Marker** | Animated Icon | Category-colored, pulsing. Smoothly moves as location updates |
| **Buyer Marker** | Blue Dot | User's fixed location (where they'll pick up) |
| **Route Polyline** | Dashed Line | Vendor's planned route (if active) |
| **Completed Route** | Solid Line | Part of route already traversed (gray/green) |
| **Remaining Route** | Dashed Line | Part of route still to go (primary color) |
| **Distance Line** | Dotted Arc | Direct line between vendor and buyer |

### 2.3 Bottom Info Panel
| Element | Type | Description |
|---------|------|-------------|
| **ETA Display** | Large Text | "~3 min away" — updates live |
| **Distance** | Subtitle | "450 meters" |
| **Speed Indicator** | Small Text | "Moving at ~12 km/h" (calculated from consecutive updates) |
| **Order Status** | Badge | "⏳ Requested" / "✅ Accepted" / "🎉 Fulfilled" |
| **Vendor Contact** | Button | "📞 Call Vendor" (opens phone dialer) |

### 2.4 Proximity Alert
| Element | Type | Description |
|---------|------|-------------|
| **Alert Banner** | Full-width banner | "🎉 Vendor is here! (~50m away)" — slides down from top |
| **Alert Vibration** | Haptic | Phone vibrates when vendor enters <100m |

---

## 3. UI States

| State | Description |
|-------|-------------|
| **Connecting** | Map loaded, "Connecting to live feed..." spinner |
| **Live Tracking** | Vendor marker moves in real-time, ETA updates |
| **Vendor Nearby** | Alert banner shows, marker enlarged, pulsing intensity increases |
| **Vendor Passed** | "Vendor has passed your area" — order may be expired |
| **Connection Lost** | "Connection lost. Reconnecting..." with spinner |
| **Vendor Offline** | "Vendor has stopped selling" — show last known position |
| **Order Fulfilled** | Celebration animation 🎉 — "Order complete!" |

---

## 4. Design Pro Tips

### 🗺️ Map Excellence
- **Custom map style**: Dark mode map (dark gray background, light roads) for a premium tracking feel. Light mode alternative: muted/desaturated palette.
- **Vendor marker**: NOT a generic pin. Use a circular avatar with the category emoji (🐟) on a colored circle (48x48px). Add a subtle shadow.
- **Movement animation**: Smooth `250ms` linear interpolation between position updates. NEVER teleport the marker.
- **Auto-follow mode**: Map auto-centers on vendor by default. If user pans away manually, show a "Re-center" FAB. Tap to resume auto-follow.
- **Zoom level**: Auto-zoom to fit both vendor and buyer markers with 20% padding.

### 📏 Route Visualization
- **Completed segments**: Gray solid line with increased thickness (4px).
- **Current segment**: Animated "ant trail" (moving dashes) in primary color (6px).
- **Future segments**: Light dashed line (2px, muted color).
- **Waypoint markers**: Small circles at each point. Current waypoint is larger + colored.
- **Route progress bar**: Optional linear progress bar at top of screen showing overall route progress (e.g., "Waypoint 3/7").

### ⏱️ ETA Display
- **Large typography**: ETA should be the most prominent element in the bottom panel (28-32px bold).
- **Color coding**: Green (<5 min), Yellow (5-15 min), Orange (>15 min).
- **Animation**: Smooth number transition when ETA changes (don't jump from "5" to "3" — animate through).
- **Accuracy disclaimer**: Show "(approx.)" in small text — because ETAs are estimated.

### 🎯 Proximity Experience
- **Progressive intensity**: As vendor approaches:
  - 500m: Subtle notification chime
  - 200m: Vendor marker gets a glow ring
  - 100m: Full-screen banner + haptic vibration + marker enlarged
  - 50m: Pulsing alert, "VENDOR IS HERE" banner in green
- **Auto-zoom**: When vendor enters 200m zone, zoom map to show both markers closely.

### 🔄 Real-Time Performance
- **Update throttle**: Process vendor location updates at max 1 per second (even if server sends faster).
- **Interpolation**: Between updates, interpolate vendor position along the bearing for smoother movement.
- **Battery awareness**: If vendor hasn't moved in 30s, reduce update frequency. Resume when movement detected.
- **Reconnection**: On socket disconnect, auto-reconnect with exponential backoff (1s, 2s, 4s, 8s, max 30s). Show reconnecting indicator.

### 🎬 Animations
- **Screen entry**: Map fade-in + camera zoom to vendor location.
- **ETA update**: Number morph animation.
- **Proximity alert**: Slide-down banner + pulse.
- **Order fulfilled**: Confetti/particle effect + green checkmark.

---

## 5. Backend API Integration

### 5.1 Socket.IO Events (Primary)

| Event | Direction | Payload | Action |
|-------|-----------|---------|--------|
| `vendor_location_update` | Server → Client | `{ vendor_id, lat, lng, timestamp }` | Move vendor marker, recalculate distance/ETA |
| `vendor_nearby` | Server → Client | `{ vendor_id, distance_meters }` | Show proximity alert |
| `order_update` | Server → Client | `{ order_id, status }` | Update order status badge |
| `order_expired` | Server → Client | `{ order_id }` | Show "Vendor has passed" state |
| `route_progress_update` | Server → Client | `{ vendor_id, current_route_index }` | Update route progress visualization |

### 5.2 REST APIs (Supplementary)

| API | Endpoint | Purpose |
|-----|----------|---------|
| Vendor Details | `GET /vendors/:id` | Initial vendor info on mount |
| Vendor Route | `GET /vendors/:id/route` | Route polyline for map |
| Vendor ETA | `GET /vendors/:id/eta?lat=&lng=` | Initial ETA (then calculated client-side from socket updates) |
| Order Details | `GET /orders/:id` | Current order status |

### 5.3 Client-Side ETA Calculation

```javascript
// Calculate ETA from live position updates
function calculateETA(vendorLat, vendorLng, buyerLat, buyerLng) {
  const R = 6371000; // Earth radius in meters
  const dLat = toRad(buyerLat - vendorLat);
  const dLng = toRad(buyerLng - vendorLng);
  const a = Math.sin(dLat/2)**2 + 
            Math.cos(toRad(vendorLat)) * Math.cos(toRad(buyerLat)) *
            Math.sin(dLng/2)**2;
  const distance = R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
  
  const AVG_SPEED_MPS = 15000 / 3600; // 15 km/h in m/s
  const etaSeconds = distance / AVG_SPEED_MPS;
  
  return {
    distance_meters: Math.round(distance),
    eta_minutes: Math.ceil(etaSeconds / 60)
  };
}
```

---

## 6. Proximity Logic (Server-Side Reference)

```
Vendor location update received
    │
    ├── Calculate distance to each active order's buyer_lat/buyer_lng
    │
    ├── IF distance < 100m AND has_entered_zone = false
    │   ├── Set has_entered_zone = true
    │   ├── Emit 'vendor_nearby' socket event
    │   └── Send FCM push: "📍 Vendor is Nearby!"
    │
    └── IF distance > 120m AND has_entered_zone = true
        ├── Set order status = 'expired'
        ├── Emit 'order_expired' socket event
        └── Send FCM push: "⏰ Order Expired"
```

**Buffer zone**: 100m enter / 120m exit (20m hysteresis prevents flapping at boundary).

---

## 7. Analytics Events

| Event Name | Trigger | Properties |
|------------|---------|------------|
| `screen_view_live_tracking` | Screen opens | `{ vendor_id, order_id }` |
| `tracking_vendor_nearby` | Proximity alert | `{ distance_meters }` |
| `tracking_vendor_passed` | Order expired | `{ order_id }` |
| `tracking_reconnect` | Socket reconnected | `{ downtime_seconds }` |
| `tracking_call_vendor` | Call button tapped | `{ vendor_id }` |

---

*Previous: [← Order Token](./06_order_token_page.md) | Next: [Notifications →](./08_notifications.md)*
