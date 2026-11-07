# ✏️ Seller App — Add / Edit Item Page

> Page ID: `SELLER-06` | Priority: **P1 (High)** | Type: **Product Management**

---

## 1. Screen Overview

A focused form for adding new items or editing existing ones. Should be **fast and simple** — vendors add items while on the go, so the form must be completable in under 30 seconds.

---

## 2. UI Elements & Layout

### 2.1 Header
| Element | Type | Description |
|---------|------|-------------|
| **Close / Back** | Icon Button | Dismiss the form |
| **Title** | Text | "Add New Item" or "Edit Item" |

### 2.2 Form Fields
| Field | Type | Placeholder | Validation |
|-------|------|-------------|------------|
| **Item Name** | Text Input | "e.g., King Fish" | Required, 1-100 chars |
| **Price** | Number Input | "₹ 0.00" | Required, > 0 |
| **Quantity** | Number Input | "e.g., 5" | Optional, >= 0 |
| **Available** | Toggle Switch | On by default | Boolean |

### 2.3 Actions
| Element | Type | Description |
|---------|------|-------------|
| **Save Button** | Primary CTA | "Save Item" / "Update Item" |
| **Delete Button** | Destructive (edit mode only) | "Delete Item" — red text |

---

## 3. Design Pro Tips

### 📝 Form Design
- **Bottom sheet or full-screen modal**: Use bottom sheet on mobile for quick entry. Full screen for edit mode.
- **Auto-focus**: Focus on "Item Name" field on open.
- **Keyboard-aware**: Scroll form up when keyboard opens — ensure the active field is always visible.
- **Price input**: Show ₹ prefix as a non-editable decorator. Use decimal keyboard.
- **Quantity**: Optional field. If left empty, defaults to 0.
- **Category field (future)**: Dropdown: Fish, Vegetables, Meat, Eggs, Flowers, Others. Currently not in API — prepare UI space.

### ⚡ Speed Optimizations
- **Quick-add mode**: After saving an item, don't close the form. Clear fields and show "Item added! Add another?" — great for initial inventory setup.
- **Pre-fill from history**: Suggest previously used item names as autocomplete.
- **Recent prices**: Show last used price as suggestion.

### 🎬 Animations
- **Form slide-up**: Bottom sheet slides up with spring physics.
- **Save success**: Green checkmark flash + dismiss.
- **Field validation**: Shake animation on invalid fields.

---

## 4. Backend API Integration

### Add Item
| Endpoint | `POST /seller/items` |
|----------|----------------------|
| **Auth** | ✅ Seller role |
| **Body** | `{ "name": "King Fish", "price": 450, "quantity": 5, "is_available": true }` |

### Update Item
| Endpoint | `PUT /seller/items/:id` |
|----------|-------------------------|
| **Auth** | ✅ Seller role |
| **Body** | Partial update: `{ "price": 500 }` |

### Delete Item
| Endpoint | `DELETE /seller/items/:id` |
|----------|---------------------------|
| **Auth** | ✅ Seller role |

---

*Previous: [← Inventory](./05_inventory.md) | Next: [Start Selling Mode →](./07_start_selling_mode.md)*
