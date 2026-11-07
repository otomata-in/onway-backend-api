# 🗺️ Seller App — Route Setup Screen

> Page ID: `SELLER-03` | Priority: **P0 (Critical — Core Feature)** | Type: **Route Creation**

---

## 1. Screen Overview

The Route Setup Screen allows vendors to create **predefined selling routes** with waypoints. This is a **core differentiating feature** of OnWay — it enables route-based prediction, ETA calculation, and buyer discovery. Vendors define start point, end point, and intermediate waypoints by tapping on the map.

---

## 2. UI Elements & Layout

### 2.1 Header
| Element | Type | Description |
|---------|------|-------------|
| **Back Arrow** | Icon Button | Returns to Route Management |
| **Title** | Text | "Create New Route" |
| **Save Button** | Text Button | "Save" — top right, active when valid |

### 2.2 Route Name Input
| Element | Type | Description |
|---------|------|-------------|
| **Name Field** | Text Input | "Route Name" — e.g., "Morning - Kaloor to Edappally" |

### 2.3 Map Canvas
| Element | Type | Description |
|---------|------|-------------|
| **Full Map** | Interactive Map | ~70% of screen, center of UI |
| **Start Marker** | 🟢 Green Pin | First tap = start point |
| **Waypoint Markers** | 🔵 Blue Pins | Intermediate taps = waypoints |
| **End Marker** | 🔴 Red Pin | Last point = end (or explicitly set) |
| **Route Polyline** | Connecting Line | Straight lines between waypoints (sequence order) |
| **Sequence Numbers** | Badge on Marker | "1", "2", "3" — order of points |

### 2.4 Waypoint Controls
| Element | Type | Description |
|---------|------|-------------|
| **Add Point Instruction** | Banner | "Tap on the map to add waypoints" |
| **Waypoint List** | Scrollable List | Below map — list of all added points |
| **Reorder** | Drag Handle | ☰ drag handles to reorder points |
| **Delete Point** | X Button | Remove individual waypoint |
| **Clear All** | Text Button | "Clear All Points" |

### 2.5 Waypoint List Item
| Element | Description |
|---------|-------------|
| **Sequence Number** | "#1", "#2", etc. |
| **Coordinates** | "10.0123, 76.3456" (or reverse-geocoded address if available) |
| **Type Label** | "Start" (first), "Waypoint" (middle), "End" (last) |
| **Drag Handle** | ☰ for reordering |
| **Delete** | ✕ button |

### 2.6 Bottom Actions
| Element | Type | Description |
|---------|------|-------------|
| **Undo** | Icon Button | Undo last point addition |
| **My Location** | FAB | Center map on current GPS |
| **Save Route** | Primary CTA | "Save Route" — full width at bottom |

---

## 3. UI States

| State | Description |
|-------|-------------|
| **Empty** | Map shown, instruction banner: "Tap on the map to add your first waypoint" |
| **1 Point** | Start marker placed, "Add more waypoints" |
| **2+ Points** | Route line drawn, Save button becomes active |
| **Reordering** | Drag mode active, map markers update live on reorder |
| **Saving** | Save button shows spinner, inputs disabled |
| **Saved** | Success toast, navigate back to Route Management |
| **Error** | "Failed to save route" with retry option |
| **Edit Mode** | Pre-populated with existing route data (for editing) |

---

## 4. Design Pro Tips

### 🗺️ Map Interaction
- **Tap to add**: Single tap on map = add waypoint at that location. This is the most intuitive method.
- **Long press alternative**: Optional long-press for precision placement (shows a crosshair).
- **Marker dragging**: Allow dragging existing markers to adjust position.
- **Snap to road**: If using a directions API, snap waypoints to the nearest road (advanced, optional).
- **Reverse geocoding**: Show human-readable address for each point when possible ("Near Fish Market, Ernakulam").

### 📏 Route Line
- **Straight lines**: For MVP, connect waypoints with straight lines. Road-following routes can come later.
- **Line style**: 4px dashed line in primary color. Different segments get different colors for clarity.
- **Direction arrows**: Small chevrons (>) on the line showing travel direction.
- **Distance labels**: Show distance between consecutive waypoints in small labels on the line.

### 🔢 Waypoint Management
- **Reorder by drag**: Allow drag-and-drop in the waypoint list. Map markers + polyline update in real time.
- **Max waypoints**: Limit to 20 points per route (prevents abuse, keeps map clean).
- **Min waypoints**: Require at least 2 points to save a route.
- **Validation**: Show error if route name is empty.

### 📱 Vendor UX Considerations
- **Large map tap target**: When in "add mode", the map should have generous tap tolerance (the nearest road/intersection).
- **Clear visual feedback**: When a point is added, show a brief animation (marker drops in, list scrolls to new item).
- **Undo support**: Critical for map-based interactions. Mis-taps are common.
- **Preview**: After adding all points, show a "Preview Route" animation — camera flies along the route.

### 🎬 Animations
- **Marker drop**: Markers drop from above with a bounce (like Google Maps pin drop).
- **Line draw**: Route line draws progressively from start to each new point.
- **Reorder**: List items slide smoothly on drag. Map markers swap positions with animation.
- **Save**: Zoom out to show full route → success checkmark → navigate away.

---

## 5. Backend API Integration

### 5.1 Create Route

| Property | Value |
|----------|-------|
| **Endpoint** | `POST /seller/routes` |
| **Auth Required** | ✅ Yes (Seller role) |

**Request Body:**
```json
{
  "name": "Morning Route - Kaloor to Edappally",
  "points": [
    { "lat": 10.01, "lng": 76.30, "sequence": 1 },
    { "lat": 10.02, "lng": 76.31, "sequence": 2 },
    { "lat": 10.03, "lng": 76.32, "sequence": 3 },
    { "lat": 10.04, "lng": 76.33, "sequence": 4 }
  ]
}
```

**Success Response (201):**
```json
{
  "success": true,
  "data": {
    "id": 3,
    "vendor_id": 1,
    "name": "Morning Route - Kaloor to Edappally",
    "is_active": false,
    "points": [
      { "id": 1, "lat": 10.01, "lng": 76.30, "sequence": 1 },
      { "id": 2, "lat": 10.02, "lng": 76.31, "sequence": 2 },
      { "id": 3, "lat": 10.03, "lng": 76.32, "sequence": 3 },
      { "id": 4, "lat": 10.04, "lng": 76.33, "sequence": 4 }
    ]
  }
}
```

**Server-side actions:**
1. Creates `VendorRoute` record (is_active: false)
2. Creates `VendorRoutePoint` records in sequence order
3. All within a DB transaction

### 5.2 Update Route

| Property | Value |
|----------|-------|
| **Endpoint** | `PUT /seller/routes/:id` |
| **Auth Required** | ✅ Yes |

**Request:** Same structure as create. Can update name and/or points.

**Note:** When points are updated, all existing points are deleted and new ones are created (full replacement, not patch).

### 5.3 Error Responses

| Status | Code | Message | UI Action |
|--------|------|---------|-----------|
| 400 | `VALIDATION_ERROR` | "Route name is required" | Highlight name field |
| 400 | `VALIDATION_ERROR` | "At least 2 points required" | Show error toast |
| 404 | `ROUTE_NOT_FOUND` | "Route not found" | Navigate back |
| 404 | `VENDOR_NOT_FOUND` | "Vendor profile not found" | Navigate to registration |

---

## 6. Validation Rules

| Field | Rule | Error Message |
|-------|------|---------------|
| Name | Required, 1-100 chars | "Route name is required" |
| Points | Minimum 2 points | "Add at least 2 waypoints" |
| Points | Maximum 20 points | "Maximum 20 waypoints per route" |
| Point.lat | -90 to 90 | "Invalid latitude" |
| Point.lng | -180 to 180 | "Invalid longitude" |
| Point.sequence | Sequential integers starting from 1 | Auto-generated by frontend |

---

## 7. Analytics Events

| Event Name | Trigger | Properties |
|------------|---------|------------|
| `screen_view_route_setup` | Screen opens | `{ mode: "create" or "edit" }` |
| `waypoint_added` | Map tapped to add point | `{ point_count }` |
| `waypoint_removed` | Point deleted | `{ point_count }` |
| `waypoints_reordered` | Drag reorder completed | — |
| `route_saved` | Save successful | `{ point_count, route_id }` |
| `route_save_failed` | Save error | `{ error_code }` |

---

*Previous: [← Dashboard](./02_dashboard.md) | Next: [Route Management →](./04_route_management.md)*
