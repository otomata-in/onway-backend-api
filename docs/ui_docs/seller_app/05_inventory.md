# 📋 Seller App — Inventory Page

> Page ID: `SELLER-05` | Priority: **P0 (Critical)** | Type: **Product Management**

---

## 1. Screen Overview

The Inventory page lets sellers **manage their product catalog** — add new items, update prices and quantities, toggle availability, and remove items. This is what buyers see when they view the vendor's details, so keeping it updated is critical.

---

## 2. UI Elements & Layout

### 2.1 Header
| Element | Type | Description |
|---------|------|-------------|
| **Back Arrow** | Icon Button | Returns to Dashboard |
| **Title** | Text | "My Items" |
| **Add Button** | FAB / Button | "＋ Add Item" |

### 2.2 Item Cards
| Element | Type | Description |
|---------|------|-------------|
| **Item Name** | Title | "King Fish (Ayakura)" |
| **Price** | Subtitle | "₹450/kg" |
| **Quantity** | Badge | "5 kg" |
| **Availability Toggle** | Switch | 🟢 On / 🔴 Off |
| **Edit Button** | Icon | ✏️ — opens edit modal |
| **Delete Button** | Icon | 🗑️ — soft delete with confirmation |

### 2.3 Quick Stats
| Element | Type | Description |
|---------|------|-------------|
| **Total Items** | Badge | "15 items" |
| **Available** | Badge | "12 available" |
| **Out of Stock** | Badge | "3 unavailable" |

### 2.4 Empty State
| Element | Description |
|---------|-------------|
| **Illustration** | Basket/cart with items |
| **Text** | "No items yet" + "Add your first product to start selling" |
| **CTA** | "Add Item" button |

---

## 3. Design Pro Tips

### 📋 Item Card Design
- **List layout**: Full-width cards, 80px height. Name left, price center-right, toggle far right.
- **Availability toggle**: Standard switch/toggle. Green = available to buyers. Red = hidden.
- **Instant toggle**: Availability change should be immediate (optimistic update) with background API call.
- **Sold out styling**: Unavailable items get reduced opacity (0.5) and "Sold Out" red label.
- **Group by availability**: Show available items first, then unavailable in a separate section.

### ➕ Add/Edit Item Form
- **Modal or bottom sheet**: Not a full-page navigation — keep it fast.
- **Fields**: Name (text), Price (number with ₹ prefix), Quantity (number with unit), Available (toggle).
- **Pre-populated units**: Suggest common units: "kg", "piece", "dozen", "bundle".
- **Numeric keyboards**: Price and quantity fields should open numeric keyboard.
- **Validation**: Name required. Price > 0. Quantity >= 0.

### 🗑️ Deletion
- **Soft delete**: Items are NOT permanently deleted (historical orders reference them).
- **Confirmation**: "Delete 'King Fish'? It won't appear in your catalog anymore."
- **Visual removal**: Slide left + fade out animation.

### 📱 Vendor UX
- **Quick stock update**: Allow tapping directly on quantity to quickly change stock number (inline edit).
- **Batch operations**: "Mark all as unavailable" for end-of-day.
- **Search/filter**: If vendor has 10+ items, show a search bar.

---

## 4. Backend API Integration

### 4.1 Get All Items

| Property | Value |
|----------|-------|
| **Endpoint** | `GET /seller/items` |
| **Auth Required** | ✅ Yes (Seller role) |

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
      "is_available": true,
      "created_at": "2026-07-01T08:00:00Z",
      "updated_at": "2026-07-04T10:00:00Z"
    }
  ]
}
```

### 4.2 Add Item

| Property | Value |
|----------|-------|
| **Endpoint** | `POST /seller/items` |
| **Auth Required** | ✅ Yes |

**Request:**
```json
{
  "name": "King Fish",
  "price": 450.00,
  "quantity": 5,
  "is_available": true
}
```

### 4.3 Update Item

| Property | Value |
|----------|-------|
| **Endpoint** | `PUT /seller/items/:id` |
| **Auth Required** | ✅ Yes |

**Request:** Only send changed fields:
```json
{ "price": 500.00, "quantity": 3 }
```

### 4.4 Delete Item (Soft Delete)

| Property | Value |
|----------|-------|
| **Endpoint** | `DELETE /seller/items/:id` |
| **Auth Required** | ✅ Yes |

**Server-side:** Sets `is_deleted = true` and `is_available = false`. Item remains in DB for order history.

### 4.5 Quick Availability Toggle

Use `PUT /seller/items/:id` with `{ "is_available": false }` — same update endpoint.

---

## 5. Analytics Events

| Event Name | Trigger | Properties |
|------------|---------|------------|
| `screen_view_inventory` | Screen opens | `{ item_count }` |
| `item_added` | New item created | `{ item_name, price }` |
| `item_updated` | Item edited | `{ item_id, changed_fields }` |
| `item_deleted` | Item soft deleted | `{ item_id }` |
| `item_availability_toggled` | Toggle switched | `{ item_id, is_available }` |

---

*Previous: [← Route Management](./04_route_management.md) | Next: [Add/Edit Item →](./06_add_edit_item.md)*
