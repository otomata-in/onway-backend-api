# 🚗 Seller App — Active Delivery Mode

> Page ID: `SELLER-09` | Priority: **P1 (High)** | Type: **Navigation & Delivery**

---

## 1. Screen Overview

Active Delivery Mode provides the vendor with a **navigation-style view** when they're actively selling and following a route. It shows the route on a map, nearby buyers with active orders, and prioritizes orders by proximity. Think of it as a **simplified navigation app optimized for street vendors**.

---

## 2. UI Elements & Layout

### 2.1 Map View (Full Screen)
| Element | Type | Description |
|---------|------|-------------|
| **Route Polyline** | Colored Line | Active route with progress |
| **Current Position** | Vendor Marker | GPS-tracked, auto-centered |
| **Buyer Pins** | Blue Markers | Buyers with active/accepted orders |
| **Next Waypoint** | Highlighted Pin | Next point on route — emphasized |
| **Distance to Next** | Floating Badge | "250m to next waypoint" |

### 2.2 Order Priority List
| Element | Type | Description |
|---------|------|-------------|
| **Bottom Sheet** | Draggable List | Orders sorted by distance (nearest first) |
| **Order Pill** | Compact Card | "King Fish x2 — 200m away" |
| **Direction Arrow** | Compass | Points towards buyer |
| **Quick Fulfill** | Button | "✅ Done" — one-tap fulfill |

### 2.3 Route Progress
| Element | Type | Description |
|---------|------|-------------|
| **Progress Bar** | Linear | "Waypoint 4/7" |
| **Route Name** | Subtitle | "Morning Route - Kaloor" |

---

## 3. Design Pro Tips

### 🧭 Navigation Experience
- **Auto-rotate map**: Map rotates with vendor's heading (like Google Maps navigation).
- **3D perspective**: Slight tilt (15-20°) for a navigation feel.
- **Next waypoint prominence**: Large, colored marker with pulsing ring.
- **Voice prompts (future)**: "New order from 200m ahead" — audio alerts while driving.

### 📦 Order Priority
- **Nearest first**: Orders sorted by real-time distance. The closest buyer is at top.
- **Color gradient**: Green (very close, <200m), Yellow (nearby, 200m-1km), dim (far, >1km).
- **Route-aware sorting**: Orders near the upcoming route get priority over orders behind the vendor.
- **One-tap fulfill**: For quick transactions — vendor meets buyer, taps "Done", continues moving.

### 📱 Driving/Walking Safety
- **Minimal interaction**: Large buttons, no text input, minimal reading required.
- **Haptic alerts**: Vibrate when approaching a buyer's zone.
- **Audio notifications**: New order arrival sound, proximity chime.
- **Speed detection**: If moving >25km/h, dim the UI and show "Focus on the road" (safety compliance).

---

## 4. Backend API Integration

| API | Endpoint | Purpose |
|-----|----------|---------|
| Active Route | `GET /seller/routes/active` | Load route polyline |
| Seller Orders | `GET /seller/orders?status=accepted` | Load accepted orders with buyer locations |
| Fulfill Order | `POST /orders/:id/fulfill` | Quick-fulfill on delivery |
| Location Update | `POST /vendors/location` | Continuous GPS (every 3-5s) |

### Socket Events

| Event | Action |
|-------|--------|
| `new_order` | Add buyer marker to map + notification |
| `route_progress_update` | Update waypoint progress (emitted by server based on location matching) |

---

## 5. Analytics Events

| Event Name | Trigger | Properties |
|------------|---------|------------|
| `delivery_mode_opened` | Screen opens | `{ route_id, order_count }` |
| `quick_fulfill_tapped` | One-tap fulfill | `{ order_id, distance_at_fulfill }` |
| `waypoint_reached` | Auto-detected | `{ waypoint_index }` |

---

*Previous: [← Orders Page](./08_orders_page.md) | Next: [Fulfillment Screen →](./10_fulfillment_screen.md)*
