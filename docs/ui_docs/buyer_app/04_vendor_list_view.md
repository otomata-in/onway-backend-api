# 📋 Buyer App — Vendor List / Card View

> Page ID: `BUYER-04` | Priority: **P1 (High)** | Type: **Discovery**

---

## 1. Screen Overview

An alternative to the map-centric home view, the Vendor List View presents all nearby vendors in a **scrollable card-based list**. Users who prefer structured browsing over map exploration use this view. It can be accessed by fully expanding the bottom sheet on the Home Screen or via a dedicated "List" toggle.

---

## 2. UI Elements & Layout

### 2.1 View Toggle
| Element | Type | Description |
|---------|------|-------------|
| **Map / List Toggle** | Segmented Control | "🗺️ Map" / "📋 List" — switches between views |

### 2.2 Sort & Filter Bar
| Element | Type | Description |
|---------|------|-------------|
| **Sort Dropdown** | Select | "Nearest First" (default), "ETA (fastest)", "Recently Active" |
| **Category Chips** | Horizontal Scroll | Same as Home Screen filter bar |
| **Favorites Toggle** | Icon Button | ♥ — Show only favorited vendors |

### 2.3 Vendor Cards (Full Width)
| Element | Type | Description |
|---------|------|-------------|
| **Category Badge** | Colored Tag | "🐟 Fish" in a colored pill |
| **Vendor Identity** | Title | "Fish Van" or masked mobile |
| **Distance** | Text | "0.5 km away" with color coding |
| **ETA** | Text | "~2 min" |
| **Item Count** | Subtitle | "12 items available" |
| **Status** | Live Indicator | 🟢 "Selling Now" / 🟡 "On Route" |
| **Route Info** | Small Text | "Heading towards your area" (if route-based) |
| **Favorite Button** | Heart Icon | Toggle favorite |
| **Card Action** | Full Tap | Navigate to Vendor Details |

### 2.4 Empty & Loading States
| Element | Description |
|---------|-------------|
| **Skeleton Cards** | 3 shimmer placeholders while loading |
| **Empty State** | Illustration + "No vendors in your area" + "Try expanding your search radius" |
| **Pull-to-Refresh** | Standard pull gesture with spinner |

---

## 3. Design Pro Tips

### 🃏 Card Design
- **Card elevation**: Subtle shadow (`0 2px 8px rgba(0,0,0,0.08)`). `border-radius: 16px`.
- **Card padding**: `16px` all sides. Minimum height: `100px`.
- **Spacing between cards**: `12px`.
- **Left accent stripe**: A 4px vertical colored stripe on the left edge matching category color (Green for vegs, Blue for fish, etc.).
- **Tap feedback**: Ripple effect on tap (Material) or highlight (iOS).

### 📊 Information Hierarchy
- **Primary**: Vendor name + category (largest text, bold).
- **Secondary**: Distance + ETA (medium text, colored badge).
- **Tertiary**: Item count + route info (smallest text, muted color).
- **Visual**: Use a clear left-to-right reading flow: Icon → Text → Distance/Action.

### 🔄 Real-Time Updates
- **Distance updates live**: As vendor moves (socket events), update distance on cards in real time.
- **Avoid full re-sorts**: Only re-sort the list when the user pulls to refresh, not on every vendor move (prevents jarring UI jumps).
- **New vendor animation**: If a new vendor appears, animate the card in (slide down + fade).

### 🎯 Interaction Design
- **Swipe-to-favorite**: Allow right-swipe on a card to toggle favorite (power user shortcut).
- **Long press**: Show a quick-action menu: "Track on Map", "View Items", "Favorite".
- **Pull-to-refresh**: Always available, with a smooth elastic animation.

---

## 4. Backend API Integration

### APIs Used (Same as Home Screen)

| API | Endpoint | Purpose |
|-----|----------|---------|
| Nearby Vendors | `GET /vendors/nearby?lat=&lng=&radius=` | Fetch vendor list |
| Vendor ETA | `GET /vendors/:id/eta?lat=&lng=` | Get ETA for each vendor |
| Toggle Favorite | `POST /vendors/:id/favorite` | Heart button |
| Get Favorites | `GET /vendors/favorites` | Filter by favorites |

### Real-Time Updates

| Socket Event | Action |
|-------------|--------|
| `vendor_location_update` | Recalculate distance for the specific vendor card |
| `vendor_nearby` | Highlight vendor card + show proximity badge |

---

## 5. Sorting Logic (Client-Side)

| Sort Option | Logic |
|-------------|-------|
| Nearest First | Sort by `distance_km` ASC |
| ETA (fastest) | Sort by `eta_minutes` ASC |
| Recently Active | Sort by last `vendor_location_update` timestamp DESC |

---

## 6. Analytics Events

| Event Name | Trigger | Properties |
|------------|---------|------------|
| `view_toggle_list` | Switched to list view | — |
| `sort_changed` | Sort dropdown changed | `{ sort_option }` |
| `vendor_card_tapped` | Card tapped | `{ vendor_id, position_in_list }` |
| `favorites_filter_toggled` | Favorites toggle | `{ enabled }` |

---

*Previous: [← Home Screen](./03_home_screen.md) | Next: [Vendor Details →](./05_vendor_details_page.md)*
