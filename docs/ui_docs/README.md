# 📱 OnWay Market — UI Documentation Hub

> Complete UI specification, design guidelines, and API integration documentation for both the Buyer and Seller mobile applications.

---

## 📁 Folder Structure

```
ui_docs/
├── README.md                      ← You are here
├── MASTER_NAVIGATION_MAP.md       ← How all screens connect + API mapping
│
├── buyer_app/                     ← Buyer (Customer) App — 10 screens
│   ├── 01_login_screen.md
│   ├── 02_otp_verification_screen.md
│   ├── 03_home_screen.md
│   ├── 04_vendor_list_view.md
│   ├── 05_vendor_details_page.md
│   ├── 06_order_token_page.md
│   ├── 07_live_tracking_page.md
│   ├── 08_notifications.md
│   ├── 09_orders_history_page.md
│   └── 10_profile_settings.md
│
└── seller_app/                    ← Seller (Vendor) App — 11 screens
    ├── 01_login_screen.md
    ├── 02_dashboard.md
    ├── 03_route_setup.md
    ├── 04_route_management.md
    ├── 05_inventory.md
    ├── 06_add_edit_item.md
    ├── 07_start_selling_mode.md
    ├── 08_orders_page.md
    ├── 09_active_delivery_mode.md
    ├── 10_fulfillment_screen.md
    └── 11_notifications.md
```

---

## 🎯 What's Inside Each Document

Every screen document contains:

| Section | Description |
|---------|-------------|
| **Screen Overview** | What the screen does and why it exists |
| **UI Elements & Layout** | Every component with type, description, and behavior |
| **UI States** | All possible states (loading, error, empty, success, etc.) |
| **Design Pro Tips** | Visual design, UX, animation, accessibility, and performance tips |
| **User Flow** | How users navigate to/from this screen |
| **Backend API Integration** | Exact endpoints, request/response, error handling |
| **Analytics Events** | What to track for product analytics |
| **Edge Cases** | Error scenarios and how to handle them |

---

## 📊 App Statistics

| Metric | Buyer App | Seller App | Total |
|--------|-----------|------------|-------|
| **Screens** | 10 | 11 | **21** |
| **REST APIs Used** | 15 | 16 | **37** (unique) |
| **Socket.IO Events** | 4 | 2 | **6** (unique) |
| **FCM Notifications** | 5 (receives) | 1 (receives) | **7** types |

---

## 🔗 Key Documents

| Document | Description |
|----------|-------------|
| [**MASTER_NAVIGATION_MAP.md**](./MASTER_NAVIGATION_MAP.md) | 🧭 How every screen connects — navigation flows, API-to-screen mapping, shared components |
| [**API Spec**](../on_way_market_api_detailed_specification.md) | Complete backend API specification |
| [**Frontend Spec**](../on_way_market_frontend_product_specification.md) | Product & feature specification |
| [**Backend Design**](../on_way_market_backend_design.md) | System architecture & database design |
| [**Task Tracker**](../../TASK_TRACKER.md) | Backend implementation status (all stages complete) |

---

## 🏗️ Tech Stack Reference

| Layer | Technology |
|-------|-----------|
| **Backend** | Node.js (Express) + Sequelize ORM |
| **Database** | MySQL |
| **Cache** | Redis (locations, OTP) |
| **Real-Time** | Socket.IO |
| **Push Notifications** | Firebase Cloud Messaging (FCM) |
| **SMS/OTP** | Twilio Verify |
| **Mobile Apps** | Flutter (recommended) |
| **Maps** | Google Maps SDK / Mapbox |

---

## 🎨 Design System Recommendations

### Color Palette

| Role | Buyer App | Seller App |
|------|-----------|------------|
| **Primary** | `#2E7D32` (Green) | `#FF8F00` (Amber) |
| **Secondary** | `#81C784` (Light Green) | `#FFB74D` (Light Amber) |
| **Background** | `#F5F7F5` | `#FFF8F0` |
| **Surface** | `#FFFFFF` | `#FFFFFF` |
| **Error** | `#D32F2F` | `#D32F2F` |
| **Success** | `#43A047` | `#43A047` |

### Typography
- **Primary Font**: Inter or Roboto
- **Headings**: Semibold/Bold weight
- **Body**: Regular weight, 15-16px
- **Captions**: 12px, muted color

### Spacing System
- Base unit: `4px`
- Component padding: `12-16px`
- Section gaps: `24-32px`
- Screen margins: `16px`

### Corner Radius
- Cards: `12-16px`
- Buttons: `12px`
- Badges/Chips: `20px` (fully rounded)
- Input fields: `8px`

---

## 🚀 Implementation Priority

### Phase 1 — MVP (P0 screens)
1. Auth (Login + OTP) — both apps
2. Buyer Home Screen (Map + Vendor Discovery)
3. Seller Dashboard + Start Selling + Location
4. Order Token System (Create + Accept/Reject/Fulfill)
5. Live Tracking (Socket.IO integration)

### Phase 2 — Core Experience (P1)
6. Vendor List/Card View
7. Notifications
8. Route System (Setup + Management)
9. Inventory Management
10. Active Delivery Mode + Fulfillment

### Phase 3 — Polish (P2)
11. Profile & Settings
12. Favorites
13. Reorder functionality
14. Search
15. Language support

---

*Generated from the OnWay Market backend codebase — 37 REST endpoints, 6 socket events, 7 notification types.*
