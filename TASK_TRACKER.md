# 📋 OnWay Market API — Master Task Tracker

> Last updated: 2026-05-16

---

## Stage 1: Foundation + Auth + User Profile ✅ COMPLETE

### 1.1 Project Foundation
- [x] Install dependencies (sequelize, ioredis, joi, cors, helmet, morgan, uuid, express-rate-limit)
- [x] Restructure project (modules/, middleware/, utils/, config/, migrations/)
- [x] Create `.sequelizerc` for Sequelize CLI
- [x] Create central config (`src/config/index.js`)
- [x] Setup Sequelize (`src/config/database.js`) — replaced raw mysql2
- [x] Setup Redis client (`src/config/redis.js`)
- [x] Delete old `src/config/db.js` and `src/index.js`
- [x] Update `package.json` scripts (dev, start, migrate, seed)
- [x] Update `.env` with all environment variables
- [x] Add `.env` to `.gitignore`

### 1.2 Utilities
- [x] `src/utils/ApiError.js` — Custom error class with factory methods
- [x] `src/utils/ApiResponse.js` — Standardized success/error/paginated responses
- [x] `src/utils/otp.js` — OTP generate, store (Redis), verify, delete
- [x] `src/utils/sms.js` — Pluggable SMS service (console logger for dev)

### 1.3 Database Models & Migrations
- [x] `User` model + migration (users table)
- [x] `Vendor` model + migration (vendors table)
- [x] `Item` model + migration (items table, soft delete scope)
- [x] `Order` model + migration (orders table)
- [x] `OrderItem` model + migration (order_items table)
- [x] `AuthToken` model + migration (auth_tokens table)
- [x] Model associations (all FKs defined in `models/index.js`)

### 1.4 Middleware
- [x] `authenticate.js` — Token auth + `authorize()` role middleware
- [x] `errorHandler.js` — Global error handler (ApiError, Sequelize, unknown)
- [x] `validate.js` — Joi validation middleware factory
- [x] `rateLimiter.js` — OTP limiter (3/5min) + general limiter (100/15min)

### 1.5 Auth Module
- [x] `POST /auth/send-otp` — Send OTP with rate limiting
- [x] `POST /auth/verify-otp` — Verify OTP, upsert user, issue token
- [x] `POST /auth/logout` — Invalidate token

### 1.6 User Module
- [x] `GET /me` — Get user profile (+ vendor info if seller)
- [x] `POST /users/fcm-token` — Save FCM token
- [x] `PUT /me/location` — Update location

### 1.7 App Entry
- [x] `src/app.js` — Express setup, middleware chain, route mounting
- [x] `src/server.js` — Startup with DB/Redis connect + graceful shutdown

### 1.8 Infra Setup (manual)
- [ ] ⏳ Redis installed and running
- [ ] ⏳ MySQL `onway` database created
- [ ] ⏳ Migrations run (`npm run migrate`)

---

## Stage 2: Seller Registration + Vendor System + Inventory ✅ COMPLETE

### 2.1 Seller Registration
- [x] `POST /seller/register` — Register buyer as seller (transaction: create vendor + upgrade role)

### 2.2 Vendor System (Seller-side)
- [x] `GET /seller/dashboard` — Dashboard (active status, order counts, item count)
- [x] `POST /vendors/status` — Toggle selling (is_active on/off)
- [x] `POST /vendors/location` — Update vendor location

### 2.3 Inventory Management (Seller-side)
- [x] `GET /seller/items` — Get seller's items
- [x] `POST /seller/items` — Add new item
- [x] `PUT /seller/items/:id` — Update item
- [x] `DELETE /seller/items/:id` — Soft delete item

### 2.4 Buyer-side Vendor Discovery
- [x] `GET /vendors/nearby?lat=&lng=&radius=` — Haversine distance calculation
- [x] `GET /vendors/:id` — Vendor details with user info
- [x] `GET /vendors/:id/items` — Vendor's available items

---

## Stage 3: Order System ✅ COMPLETE

### 3.1 Buyer-side Orders
- [x] `POST /orders` — Create order token (validates vendor/items, transaction)
- [x] `GET /orders` — Get buyer's orders (paginated, filtered by status)
- [x] `GET /orders/:id` — Order details with items (authorization check)

### 3.2 Seller-side Orders
- [x] `GET /seller/orders` — Get seller's orders (paginated, filtered by status)
- [x] `POST /orders/:id/accept` — Accept order (status: requested → accepted)
- [x] `POST /orders/:id/reject` — Reject order (status: requested → rejected)
- [x] `POST /orders/:id/fulfill` — Fulfill order (status: accepted → fulfilled)

### 3.3 Key Features
- [x] Status transition guards (can't accept already accepted order, etc.)
- [x] Authorization checks (only vendor owner can manage their orders)
- [x] Self-order prevention
- [x] Unscoped item inclusion in order history (shows deleted items)

---

## Stage 5: Route System ✅ COMPLETE

### 5.1 Database
- [x] `VendorRoute` model + migration (vendor_routes table)
- [x] `VendorRoutePoint` model + migration (vendor_route_points table)
- [x] Migration: FK constraint vendors.current_route_id → vendor_routes.id
- [x] Model associations in `models/index.js`

### 5.2 Seller Endpoints
- [x] `POST /seller/routes` — Create route with waypoints (transaction)
- [x] `GET /seller/routes` — List all saved routes
- [x] `PUT /seller/routes/:id` — Update route (name and/or points)
- [x] `DELETE /seller/routes/:id` — Delete route (can't delete active)
- [x] `POST /seller/routes/:id/activate` — Activate route (deactivates previous)
- [x] `GET /seller/routes/active` — Get currently active route

### 5.3 Buyer-side
- [x] `GET /vendors/:id/route` — Vendor's active route (for map display)

---

## Stage 4: Realtime System (Socket.IO) ✅ COMPLETE

### 4.1 Socket.IO Setup
- [x] Install socket.io dependency
- [x] `src/config/socket.js` — Socket.IO init with auth middleware + connection handler
- [x] Socket authentication (token-based, validates via auth_tokens table)
- [x] Channel structure (vendor_user_{id}, buyer_{id})
- [x] Integrated with HTTP server in `server.js` via `http.createServer()`

### 4.2 Socket Events
- [x] `location_update` — Seller → Server (live GPS via socket + REST)
- [x] `vendor_location_update` — Server → All (broadcast vendor position)
- [x] `new_order` — Server → Seller (when buyer creates order token)
- [x] `order_update` — Server → Buyer (when seller accepts/rejects/fulfills)
- [x] `vendor_nearby` — Server → Buyer (proximity enter zone <100m)
- [x] `order_expired` — Server → Buyer (proximity exit zone >120m)

### 4.3 Proximity Detection
- [x] Enter zone (<100m) → `vendor_nearby` notification to buyer
- [x] Exit zone (>120m after enter) → expire order + `order_expired` notification
- [x] Debounce logic (3s per order) with memory leak prevention

### 4.4 Utilities Created
- [x] `src/utils/socketEmitter.js` — Named emitter methods (notifyNewOrder, notifyOrderUpdate, etc.)
- [x] `src/utils/proximity.js` — Haversine distance, enter/exit zone, debounce
- [x] Redis integration for real-time vendor location storage (TTL 1hr)

### 4.5 Service Integrations
- [x] `order.service.js` — Emits `new_order` + `order_update` events
- [x] `seller.service.js` — Redis write + socket broadcast + proximity check on location update

---

## Stage 6: Notifications (FCM) ✅ COMPLETE

### 6.1 Setup
- [x] Install firebase-admin dependency
- [x] `FIREBASE_SERVICE_ACCOUNT_PATH` added to `.env` + `config/index.js`
- [x] `firebase-service-account.json` added to `.gitignore`
- [x] `src/utils/fcm.js` — Firebase Admin SDK init with graceful degradation (console logging in dev)
- [x] `src/utils/notificationService.js` — High-level notification methods

### 6.2 Notification Events
- [x] `new_order` → Seller push ("🛒 New Order Received!")
- [x] `order_accepted` → Buyer push ("✅ Order Accepted!")
- [x] `order_rejected` → Buyer push ("❌ Order Declined")
- [x] `order_fulfilled` → Buyer push ("🎉 Order Complete!")
- [x] `vendor_nearby` → Buyer push ("📍 Vendor is Nearby!")
- [x] `order_expired` → Buyer push ("⏰ Order Expired")
- [x] `vendor_upcoming` → Buyer push ("🚚 Vendor Coming Your Way!") — route-based, method ready

### 6.3 Integration Points
- [x] `order.service.js` — FCM on create order + status changes
- [x] `proximity.js` — FCM on enter zone + exit zone
- [x] `server.js` — `initFirebase()` called during startup
- [x] Dual delivery: Socket.IO (realtime) + FCM (push when app is backgrounded)

---

## Stage 7: Optimization + Extras ✅ COMPLETE

### 7.1 Performance
- [x] Redis caching for vendor locations (nearby query enriched with Redis-cached positions)
- [x] Batch DB writes for location updates (`src/utils/locationSync.js` — 30s interval Redis → MySQL sync)
- [x] Query optimization — 4 composite indexes added (migration 011)

### 7.2 Extras
- [x] `GET /vendors/:id/eta?lat=&lng=` — ETA based on Haversine distance (15 km/h assumption)
- [x] `POST /vendors/:id/favorite` — Toggle favorite vendor
- [x] `GET /vendors/favorites` — Get buyer's favorite vendors
- [x] `GET /admin/active-vendors` — Admin: all currently active vendors
- [x] API documentation — Swagger UI at `/api-docs` (30 paths, full schemas)

### 7.3 Database
- [x] `Favorite` model + migration (favorites table, unique user-vendor constraint)
- [x] Performance indexes migration (011)

---

## 🎉 ALL STAGES COMPLETE

## Progress Summary

| Stage | Description | Status | Endpoints |
|-------|-------------|--------|-----------|
| 1 | Foundation + Auth + User | ✅ Complete | 7/7 |
| 2 | Seller + Vendor + Inventory | ✅ Complete | 10/10 |
| 3 | Order System | ✅ Complete | 7/7 |
| 5 | Route System | ✅ Complete | 7/7 |
| 4 | Realtime (Socket.IO) | ✅ Complete | 6/6 events |
| 6 | FCM Notifications | ✅ Complete | 7/7 types |
| 7 | Optimization + Extras | ✅ Complete | 5/5 |

**Total: 37 REST endpoints | 6 socket events | 7 push notification types | 30 Swagger paths | 69 source files**

---

## Complete API Endpoint Reference

| # | Method | Path | Auth | Module |
|---|--------|------|------|--------|
| 1 | `GET` | `/` | No | Health check |
| 2 | `GET` | `/api-docs` | No | Swagger UI |
| 3 | `POST` | `/auth/send-otp` | No | Auth |
| 4 | `POST` | `/auth/verify-otp` | No | Auth |
| 5 | `POST` | `/auth/logout` | Yes | Auth |
| 6 | `GET` | `/me` | Yes | User |
| 7 | `POST` | `/users/fcm-token` | Yes | User |
| 8 | `PUT` | `/me/location` | Yes | User |
| 9 | `POST` | `/seller/register` | Yes | Seller |
| 10 | `GET` | `/seller/dashboard` | Seller | Seller |
| 11 | `GET` | `/seller/orders` | Seller | Order |
| 12 | `GET` | `/seller/items` | Seller | Inventory |
| 13 | `POST` | `/seller/items` | Seller | Inventory |
| 14 | `PUT` | `/seller/items/:id` | Seller | Inventory |
| 15 | `DELETE` | `/seller/items/:id` | Seller | Inventory |
| 16 | `POST` | `/seller/routes` | Seller | Route |
| 17 | `GET` | `/seller/routes` | Seller | Route |
| 18 | `GET` | `/seller/routes/active` | Seller | Route |
| 19 | `PUT` | `/seller/routes/:id` | Seller | Route |
| 20 | `DELETE` | `/seller/routes/:id` | Seller | Route |
| 21 | `POST` | `/seller/routes/:id/activate` | Seller | Route |
| 22 | `POST` | `/vendors/status` | Seller | Vendor |
| 23 | `POST` | `/vendors/location` | Seller | Vendor |
| 24 | `GET` | `/vendors/nearby` | Yes | Vendor |
| 25 | `GET` | `/vendors/favorites` | Yes | Vendor |
| 26 | `GET` | `/vendors/:id` | Yes | Vendor |
| 27 | `GET` | `/vendors/:id/items` | Yes | Vendor |
| 28 | `GET` | `/vendors/:id/route` | Yes | Vendor |
| 29 | `GET` | `/vendors/:id/eta` | Yes | Vendor |
| 30 | `POST` | `/vendors/:id/favorite` | Yes | Vendor |
| 31 | `POST` | `/orders` | Yes | Order |
| 32 | `GET` | `/orders` | Yes | Order |
| 33 | `GET` | `/orders/:id` | Yes | Order |
| 34 | `POST` | `/orders/:id/accept` | Seller | Order |
| 35 | `POST` | `/orders/:id/reject` | Seller | Order |
| 36 | `POST` | `/orders/:id/fulfill` | Seller | Order |
| 37 | `GET` | `/admin/active-vendors` | Yes | Admin |

