# OnWay Market — Detailed API Specification (Buyer + Seller Apps) — COMPLETE

> Includes all endpoints, request/response, and logic. Production-ready, agent-friendly.

---

## 0. Conventions
- Auth header: `Authorization: Bearer <token>`
- Pagination: `?page=1&limit=20`
- Error format:
```json
{ "error": true, "message": "...", "code": "..." }
```

---

# 1. AUTHENTICATION

## 1.1 Send OTP
POST /auth/send-otp
```json
{ "mobile": "9876543210" }
```
Logic: generate OTP → store in Redis (TTL 5 min) → send SMS → rate limit (max 3/5min)

## 1.2 Verify OTP
POST /auth/verify-otp
```json
{ "mobile": "9876543210", "otp": "123456" }
```
Response:
```json
{ "token": "...", "user": { "id": 1, "role": "buyer" } }
```
Logic: validate OTP → upsert user → issue token → store token

---

# 2. USER / PROFILE

## 2.1 Get Current User
GET /me

## 2.2 Save FCM Token
POST /users/fcm-token
```json
{ "token": "fcm_token" }
```
Logic: store (support multiple tokens per user optional)

## 2.3 Update User Location (optional)
PUT /me/location
```json
{ "lat": 10.12, "lng": 76.34 }
```

---

# 3. SELLER REGISTRATION

## 3.1 Register as Seller
POST /seller/register
```json
{ "vehicle_name": "Fish Van" }
```
Logic: create vendor row, set role=seller

---

# 4. BUYER APP APIs

## 4.1 Nearby Vendors
GET /vendors/nearby?lat=&lng=&radius=
Response: list with distance, eta

## 4.2 Vendor Details
GET /vendors/:id

## 4.3 Vendor Items
GET /vendors/:id/items

## 4.4 Vendor Route (for map)
GET /vendors/:id/route

## 4.5 Vendor ETA
GET /vendors/:id/eta?lat=&lng=

## 4.6 Favorite Vendor
POST /vendors/:id/favorite
GET /vendors/favorites

## 4.7 Create Order Token
POST /orders
```json
{
  "vendor_id": 2,
  "buyer_lat": 10.12,
  "buyer_lng": 76.34,
  "items": [{ "item_id": 1, "qty": 2 }]
}
```
Logic: create order → emit socket to vendor

## 4.8 Get Orders
GET /orders?page=&limit=

## 4.9 Get Order Details
GET /orders/:id

---

# 5. SELLER APP APIs

## 5.1 Dashboard
GET /seller/dashboard

## 5.2 Toggle Selling
POST /vendors/status
```json
{ "is_active": true }
```

## 5.3 Update Location
POST /vendors/location
```json
{ "lat": 10.12, "lng": 76.34 }
```
Logic: write to Redis → broadcast socket → periodic DB sync

---

# 6. INVENTORY (CRITICAL)

## 6.1 Get Items
GET /seller/items

## 6.2 Add Item
POST /seller/items

## 6.3 Update Item
PUT /seller/items/:id

## 6.4 Delete Item (soft)
DELETE /seller/items/:id

---

# 7. ORDERS (SELLER SIDE)

## 7.1 Get Seller Orders
GET /seller/orders?status=pending

## 7.2 Accept Order
POST /orders/:id/accept

## 7.3 Reject Order
POST /orders/:id/reject

## 7.4 Fulfill Order
POST /orders/:id/fulfill

---

# 8. ROUTE SYSTEM

## 8.1 Create Route
POST /seller/routes

## 8.2 Get Routes
GET /seller/routes

## 8.3 Update Route
PUT /seller/routes/:id

## 8.4 Delete Route
DELETE /seller/routes/:id

## 8.5 Activate Route
POST /seller/routes/:id/activate

## 8.6 Get Active Route
GET /seller/routes/active

---

# 9. REALTIME (SOCKET.IO)

## Auth
socket.connect({ token })

## Channels
vendor_{id}, buyer_{id}

## Events
- location_update (seller→server)
- vendor_location_update (server→buyer)
- new_order
- order_update
- vendor_nearby
- order_expired
- route_progress_update

---

# 10. PROXIMITY LOGIC

- Enter <100m → notify buyer
- Exit >120m (after enter) → expire order
- Debounce 3–5 sec

---

# 11. FCM NOTIFICATIONS

Types:
- new_order (seller)
- order_accepted (buyer)
- vendor_nearby (buyer)
- order_expired (buyer)
- vendor_upcoming (buyer)

---

# 12. ADMIN (OPTIONAL)

GET /admin/active-vendors

---

# 13. PERFORMANCE & SAFETY

- Use Redis for locations, OTP
- Limit location updates (2–3s)
- DB writes batched
- Index queries
- Soft delete fields

---

# END OF DOCUMENT

