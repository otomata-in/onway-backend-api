# 🗺️ Buyer App — Home Screen (Live Map)

> Page ID: `BUYER-03` | Priority: **P0 (Critical)** | Type: **Core Experience**

---

## 1. Screen Overview

The Home Screen is the **heart of the buyer experience**. It displays an interactive map with real-time vendor locations, allowing users to discover nearby vendors, see their categories, and interact with them. This screen must feel **alive** — vendors should visibly move on the map as they update their location in real time.

---

## 2. UI Elements & Layout

### 2.1 Top Bar
| Element | Type | Description |
|---------|------|-------------|
| **Location Label** | Text + Icon | "📍 Kaloor, Kochi" — current address. Tappable to change |
| **Notification Bell** | Icon Button | Top-right. Badge count for unread notifications |
| **Search Icon** | Icon Button | Opens search overlay |

### 2.2 Map View (Primary)
| Element | Type | Description |
|---------|------|-------------|
| **Map Container** | Interactive Map | Full-width, ~60% of screen height. Google Maps / Mapbox |
| **User Location Marker** | Pulsing Dot | Blue pulsing circle — user's current position |
| **Vendor Markers** | Custom Icons | Category-specific icons (🐟 fish, 🥬 vegetables, 🍖 meat) |
| **Vendor Cluster** | Grouped Badge | When vendors are close, show cluster count |
| **Re-center Button** | FAB | Bottom-right of map — re-centers map on user location |
| **Zoom Controls** | +/- Buttons | Optional — can use pinch-to-zoom instead |

### 2.3 Category Filter Bar
| Element | Type | Description |
|---------|------|-------------|
| **Filter Chips** | Horizontal Scroll | "All", "🐟 Fish", "🥬 Vegetables", "🍖 Meat", "🥚 Eggs", "🌺 Flowers" |
| **Active Indicator** | Chip Style | Selected chip has filled background + checkmark |

### 2.4 Bottom Sheet — Vendor List
| Element | Type | Description |
|---------|------|-------------|
| **Drag Handle** | Pill Shape | Center-top of sheet — indicates draggable |
| **Section Title** | Text | "Nearby Vendors" with count badge |
| **Vendor Cards** | Scrollable List | Each card shows vendor info (see 2.5) |
| **Pull-up to expand** | Gesture | Drag up to see full list, drag down to minimize |

### 2.5 Vendor Card (within Bottom Sheet)
| Element | Type | Description |
|---------|------|-------------|
| **Category Icon** | Avatar | Colored icon/emoji representing category |
| **Vendor Name/ID** | Title Text | "Fish Van #12" or mobile number masked |
| **Distance** | Badge | "0.5 km away" — real-time updated |
| **ETA** | Subtitle | "~2 min" |
| **Status Dot** | Indicator | 🟢 Active / 🔴 Offline |
| **Favorite Heart** | Icon Button | ♡ / ♥ — toggle favorite |
| **Tap Action** | Navigation | Opens Vendor Details (BUYER-05) |

---

## 3. UI States

| State | Description |
|-------|-------------|
| **Loading** | Map skeleton + shimmer cards in bottom sheet |
| **Vendors Found** | Map shows markers, bottom sheet lists vendors |
| **No Vendors** | Empty state: illustration + "No vendors nearby right now" + "We'll notify you when they arrive" |
| **Location Permission Denied** | Prompt to enable location: "OnWay needs your location to find nearby vendors" |
| **Map Error** | Fallback to list-only view if map fails to load |
| **Offline** | Show last cached vendors with "Offline" banner |

---

## 4. Design Pro Tips

### 🗺️ Map Design
- **Custom map style**: Use a muted/desaturated map theme (light gray streets, subtle colors) so vendor markers POP visually.
- **Vendor marker design**: Use category-colored circles with emoji icons — NOT generic pins. Size: `44x44px` for tap targets.
- **Marker animation**: When a new vendor appears, animate the marker with a "drop" effect. When a vendor moves, smoothly interpolate position (don't teleport).
- **User radius ring**: Show a subtle, semi-transparent circle around the user showing the 5km search radius.
- **Cluster design**: When 3+ vendors overlap, show a single circle with count. Color: darker shade of primary. Tap to zoom in.

### 📊 Bottom Sheet
- **Three snap points**: Peek (shows 1-2 cards), Half (shows 4-5 cards), Full (covers map).
- **Default state**: Peek — user sees the map + first 1-2 vendor cards.
- **Spring physics**: Use a spring animation for sheet drag-and-release (feels natural).
- **Blur background**: When sheet is in Full mode, slightly blur the map behind it.
- **Card hover on map**: When user scrolls over a card, highlight the corresponding marker on the map with a scale-up + bounce.

### 🎯 Vendor Card Design
- **Horizontal layout**: Icon left, text center, distance right. Single row.
- **Distance badge**: Use color coding — Green (<500m), Yellow (500m–2km), Orange (2–5km).
- **Live pulsing**: For vendors that updated location <30s ago, show a subtle "live" indicator (pulsing green dot).
- **Card elevation**: Add shadow + slight `border-radius: 12px` for floating feel.

### 🔍 Search & Filters
- **Search overlay**: Full-screen with recent searches + suggestions. NOT a small dropdown.
- **Filter chips**: Horizontal scrollable, with smooth snap. First chip "All" is always visible.
- **Active filter**: Filled background + subtle scale-up (1.05x). Count badge shows matching vendor count.
- **Multi-select**: Allow multiple category filters simultaneously.

### ⚡ Real-Time Updates
- **Socket connection**: Establish on screen mount. Listen for `vendor_location_update`.
- **Smooth marker movement**: Use `requestAnimationFrame` or map SDK's built-in animation to smoothly move markers between positions (linear interpolation over 2-3 seconds).
- **Batch updates**: Don't re-render the entire vendor list on every socket event. Batch updates every 3 seconds.
- **Stale detection**: If a vendor hasn't sent a location update in 60 seconds, dim their marker to show they may be stale.

### 📍 Location UX
- **Request location on first load** with a friendly dialog explaining WHY: "We need your location to find vendors near you"
- **Show address name** (reverse geocoding) — not coordinates. "Kaloor, Kochi" is meaningful, "10.12, 76.34" is not.
- **Allow manual location**: Some users may want to check vendors near their home while at work. Let them tap the address to search/pin a location.

### 🔔 Notification Bell
- **Badge**: Red circle with white number. Animate it (bounce) when a new notification arrives.
- **Types to show**: Vendor nearby alerts, order status changes.

---

## 5. User Flow

```
┌─────────────────────────────────┐
│         HOME SCREEN             │
│    (Live Map + Vendor List)     │
└──────┬───────────┬──────────────┘
       │           │
       │           │
  ┌────▼───┐  ┌────▼────────┐
  │ Tap    │  │ Tap Vendor  │
  │ Marker │  │ Card        │
  └────┬───┘  └────┬────────┘
       │           │
       ▼           ▼
  ┌─────────────────────┐
  │  Vendor Details     │
  │  (BUYER-05)         │
  └─────────────────────┘
       │
       ▼
  ┌─────────────────────┐     ┌──────────────┐
  │  Order Token Page   │     │ Live Tracking │
  │  (BUYER-06)         │────▶│  (BUYER-07)   │
  └─────────────────────┘     └──────────────┘

Other exits:
  Home → 🔔 → Notifications (BUYER-08)
  Home → 🔍 → Search (overlay)
  Home → Orders Tab → Orders/History (BUYER-09)
  Home → Profile Tab → Profile/Settings (BUYER-10)
```

---

## 6. Backend API Integration

### 6.1 Get Nearby Vendors

| Property | Value |
|----------|-------|
| **Endpoint** | `GET /vendors/nearby?lat={lat}&lng={lng}&radius={radius}` |
| **Auth Required** | ✅ Yes (Bearer token) |
| **Method** | GET |

**Query Parameters:**
| Param | Type | Default | Description |
|-------|------|---------|-------------|
| `lat` | float | required | User's latitude |
| `lng` | float | required | User's longitude |
| `radius` | float | 5 | Search radius in km |

**Success Response (200):**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "user_id": 5,
      "mobile": "9876543210",
      "lat": 10.0123,
      "lng": 76.3456,
      "is_active": true,
      "distance_km": 0.45
    }
  ]
}
```

**Integration Notes:**
- Call on screen mount AND when user moves the map significantly (>500m).
- Response is enriched with Redis-cached real-time locations (fresher than DB).
- Max 50 vendors returned, sorted by distance.
- Haversine formula used server-side for accurate distance calculation.

### 6.2 Get Vendor ETA

| Property | Value |
|----------|-------|
| **Endpoint** | `GET /vendors/:id/eta?lat={lat}&lng={lng}` |
| **Auth Required** | ✅ Yes |

**Response:**
```json
{
  "success": true,
  "data": {
    "vendor_id": 1,
    "distance_km": 0.45,
    "eta_minutes": 2,
    "speed_assumption_kmh": 15,
    "has_active_route": true
  }
}
```

**Note:** ETA assumes 15 km/h average speed (street vendor walking/slow vehicle).

### 6.3 Toggle Favorite Vendor

| Property | Value |
|----------|-------|
| **Endpoint** | `POST /vendors/:id/favorite` |
| **Auth Required** | ✅ Yes |

**Response:**
```json
{
  "success": true,
  "data": { "favorited": true, "vendor_id": 1 }
}
```

*Toggles: favorited → unfavorited → favorited.*

### 6.4 Get Favorite Vendors

| Property | Value |
|----------|-------|
| **Endpoint** | `GET /vendors/favorites` |
| **Auth Required** | ✅ Yes |

### 6.5 Real-Time: Socket.IO Events

| Event | Direction | Description |
|-------|-----------|-------------|
| `vendor_location_update` | Server → Client | Vendor moved. Payload: `{ vendor_id, lat, lng, timestamp }` |
| `vendor_nearby` | Server → Client | Vendor entered <100m zone. `{ vendor_id, distance_meters }` |

**Socket Connection:**
```javascript
const socket = io(API_URL, {
  auth: { token: authToken }
});

socket.on('vendor_location_update', (data) => {
  // Update vendor marker position on map
  updateVendorMarker(data.vendor_id, data.lat, data.lng);
});

socket.on('vendor_nearby', (data) => {
  // Show proximity alert
  showNearbyAlert(data.vendor_id, data.distance_meters);
});
```

---

## 7. Data Refresh Strategy

| Trigger | Action |
|---------|--------|
| Screen mount | `GET /vendors/nearby` + establish socket |
| Every 30 seconds | Re-fetch nearby vendors (timer) |
| Socket event | Update individual vendor position |
| Map drag (>500m) | Re-fetch with new center coordinates |
| Category filter change | Client-side filter (no API call needed if data is cached) |
| Pull-to-refresh on bottom sheet | Re-fetch all vendors |
| App foreground (from background) | Re-connect socket + re-fetch |

---

## 8. Edge Cases

| Scenario | Handling |
|----------|----------|
| GPS accuracy low | Show "Location accuracy is low" warning |
| User moves rapidly (driving) | Debounce re-fetch to every 10 seconds |
| 50+ vendors nearby | Show top 50 by distance, mention "50+ vendors nearby" |
| Vendor goes offline | Remove marker after 60s of no updates |
| Map SDK fails to load | Fallback to list-only view (no map) |
| Socket disconnects | Auto-reconnect with exponential backoff. Show "Reconnecting..." |

---

## 9. Analytics Events

| Event Name | Trigger | Properties |
|------------|---------|------------|
| `screen_view_home` | Screen opens | `{ vendor_count }` |
| `map_vendor_tapped` | Vendor marker tapped | `{ vendor_id, distance }` |
| `card_vendor_tapped` | Vendor card tapped | `{ vendor_id, distance }` |
| `filter_applied` | Category filter changed | `{ category, vendor_count }` |
| `search_opened` | Search icon tapped | — |
| `favorite_toggled` | Heart icon tapped | `{ vendor_id, favorited }` |
| `location_permission_denied` | User denies GPS | — |

---

*Previous: [← OTP Verification](./02_otp_verification_screen.md) | Next: [Vendor List View →](./04_vendor_list_view.md)*
