# 📍 Seller App — Route Management Screen

> Page ID: `SELLER-04` | Priority: **P1 (High)** | Type: **Route Management**

---

## 1. Screen Overview

The Route Management Screen lists all **saved routes** for the vendor. From here, sellers can activate a route, edit it, delete it, or create new ones. The currently active route is visually highlighted.

---

## 2. UI Elements & Layout

### 2.1 Header
| Element | Type | Description |
|---------|------|-------------|
| **Back Arrow** | Icon Button | Returns to Dashboard |
| **Title** | Text | "My Routes" |
| **Create New** | FAB / Button | "＋ New Route" |

### 2.2 Route Cards
| Element | Type | Description |
|---------|------|-------------|
| **Route Name** | Title | "Morning Route - Kaloor" |
| **Point Count** | Subtitle | "7 waypoints" |
| **Status Badge** | Chip | 🟢 "Active" (only one can be active) / ⚪ "Saved" |
| **Mini Map Preview** | Small Map | 80px height — shows route polyline |
| **Activate Button** | CTA | "Activate" (for inactive routes) / "Active ✓" (for current) |
| **Edit Button** | Icon | ✏️ — opens Route Setup in edit mode |
| **Delete Button** | Icon | 🗑️ — with confirmation |
| **Created Date** | Small Text | "Created 3 days ago" |

### 2.3 Empty State
| Element | Description |
|---------|-------------|
| **Illustration** | Map with route drawing |
| **Text** | "No routes yet" + "Create your first selling route" |
| **CTA** | "Create Route" button |

---

## 3. UI States

| State | Description |
|-------|-------------|
| **Loading** | Skeleton route cards (2-3 shimmer) |
| **Routes Listed** | Route cards with active/inactive status |
| **Activating** | "Activating..." loader on the activate button |
| **Delete Confirmation** | Dialog: "Delete 'Morning Route'? This cannot be undone" |
| **Delete Blocked** | "Cannot delete the active route. Deactivate first." |
| **Empty** | No routes created — empty state illustration |

---

## 4. Design Pro Tips

### 🃏 Route Card Design
- **Active route**: Green left-border (4px), slightly elevated (more shadow), green status badge.
- **Inactive routes**: Standard card, gray status.
- **Only one active**: When activating a new route, the previously active one auto-deactivates. Show this transition.
- **Mini map**: Static map thumbnail showing the route polyline. Use a muted map style.
- **Card actions**: Edit and Delete as icon buttons in the top-right corner of each card.

### ⚠️ Deletion Safety
- **Cannot delete active route**: Show toast "Deactivate this route before deleting". Disable delete button for active route.
- **Confirmation dialog**: Red "Delete" button in the confirmation dialog.
- **Undo**: Optional — show "Undo" snackbar for 5 seconds after deletion.

### 🔄 Activation Flow
- **Instant feedback**: Change button to "Activating..." spinner.
- **Success**: Green checkmark animation. Card transitions to "Active" state.
- **Previous active**: Automatically deactivates. Animate the status badge change.
- **Sets vendor state**: Activating a route sets `current_route_id` and `current_route_index = 0` on the vendor.

---

## 5. Backend API Integration

### 5.1 Get All Routes

| Property | Value |
|----------|-------|
| **Endpoint** | `GET /seller/routes` |
| **Auth Required** | ✅ Yes (Seller role) |

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": 3,
      "vendor_id": 1,
      "name": "Morning Route - Kaloor",
      "is_active": true,
      "points": [
        { "id": 1, "lat": 10.01, "lng": 76.30, "sequence": 1 },
        { "id": 2, "lat": 10.02, "lng": 76.31, "sequence": 2 }
      ]
    },
    {
      "id": 4,
      "vendor_id": 1,
      "name": "Evening Route - Fort Kochi",
      "is_active": false,
      "points": [...]
    }
  ]
}
```

### 5.2 Activate Route

| Property | Value |
|----------|-------|
| **Endpoint** | `POST /seller/routes/:id/activate` |
| **Auth Required** | ✅ Yes |

**Server-side actions:**
1. Deactivates ALL routes for this vendor
2. Activates the specified route
3. Sets `vendor.current_route_id` to this route
4. Resets `vendor.current_route_index` to 0

### 5.3 Delete Route

| Property | Value |
|----------|-------|
| **Endpoint** | `DELETE /seller/routes/:id` |
| **Auth Required** | ✅ Yes |

**Error:** 400 if trying to delete the active route.

### 5.4 Get Active Route

| Property | Value |
|----------|-------|
| **Endpoint** | `GET /seller/routes/active` |
| **Auth Required** | ✅ Yes |

---

## 6. Analytics Events

| Event Name | Trigger | Properties |
|------------|---------|------------|
| `screen_view_routes` | Screen opens | `{ route_count, has_active }` |
| `route_activated` | Route activated | `{ route_id }` |
| `route_deleted` | Route deleted | `{ route_id }` |
| `create_route_tapped` | New route button | — |
| `edit_route_tapped` | Edit icon tapped | `{ route_id }` |

---

*Previous: [← Route Setup](./03_route_setup.md) | Next: [Inventory →](./05_inventory.md)*
