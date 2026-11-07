# OnWay Market - Complete Backend Planning Document (Updated with Seller Route System)

## 1. Product Overview
OnWay Market is a real-time hyperlocal marketplace connecting buyers with moving vendors (fish, vegetables, etc.).

### Core Concept
- Not a traditional e-commerce platform
- Orders are **token-based (intent)**, not guaranteed
- Vendors fulfill based on availability
- Real-time tracking + proximity alerts
- Route-aware predictive vendor movement (NEW)

---

## 2. System Architecture

### Initial Deployment (Hostinger VPS)
```
Nginx (Reverse Proxy + SSL)
   ↓
Node.js API + Socket.IO (PM2)
   ↓
MySQL (local)
   ↓
Redis (local)
```

### Scaling Path
```
Phase 1: VPS (current)
Phase 2: AWS EC2 + RDS + Redis
Phase 3: Load balanced microservices
```

---

## 3. Tech Stack
- Backend: Node.js (Express)
- ORM: Sequelize
- DB: MySQL
- Cache: Redis
- Realtime: Socket.IO
- Notifications: Firebase FCM

---

## 4. Project Structure
```
src/
 ├── config/
 ├── models/
 ├── migrations/
 ├── modules/
 │    ├── auth/
 │    ├── vendors/
 │    ├── items/
 │    ├── orders/
 │    ├── routes/ (NEW)
 ├── middleware/
 ├── utils/
 ├── app.js
 └── server.js
```

---

## 5. Authentication System

### Flow
1. Mobile number input
2. OTP generation
3. OTP verification
4. Token issuance

### Token
- Stored in DB
- Sent via header
- Long-lived (30–90 days)

---

## 6. Database Design (UPDATED)

### users
- id
- mobile
- role
- fcm_token

### vendors
- id
- user_id
- is_active
- lat
- lng
- current_route_id (FK)
- current_route_index

### items
- id
- vendor_id
- name
- price
- quantity
- is_available

### orders (token-based)
- id
- buyer_id
- vendor_id
- status
- type (token)
- buyer_lat
- buyer_lng
- has_entered_zone
- expired_at

### order_items
- id
- order_id
- item_id
- qty

### auth_tokens
- id
- user_id
- token

### vendor_routes (NEW)
- id
- vendor_id
- name
- is_active
- created_at

### vendor_route_points (NEW)
- id
- route_id
- lat
- lng
- sequence

---

## 7. Order System (Token Logic)

### Flow
```
Buyer creates token
→ Seller receives
→ Seller accepts/rejects
→ Seller moves
→ System detects proximity
→ Buyer notified
→ Seller fulfills manually
→ If passed → expired
```

### Status Flow
```
requested → accepted → fulfilled
           ↘ rejected
           ↘ expired
```

### Route-aware Behavior (NEW)
- Orders near vendor route have higher priority
- Used for ETA prediction

---

## 8. Vendor Location System

### Features
- Live location updates
- Nearby vendor discovery
- Real-time tracking

### Optimization
- Use Redis for location storage
- DB sync every 5–10 seconds

---

## 9. Proximity Detection

### Logic
- Enter zone: <100m
- Exit zone: >120m (buffer)

### Behavior
- Notify when entering
- Expire when leaving

---

## 10. Route System (NEW CORE FEATURE)

### Purpose
- Predictable vendor movement
- Better buyer experience
- ETA prediction

### Flow
```
Seller creates route
→ activates route
→ starts selling
→ system tracks movement along route
```

### Features
- Start, end, waypoints
- Route progress tracking
- Route deviation detection

### Logic
- Track current_route_index
- Match buyers near route
- Predict ETA based on next waypoint

---

## 11. Realtime System (Socket.IO)

### Channels
- vendor_{id}
- buyer_{id}

### Events
- location_update
- vendor_location_update
- new_order
- order_update
- vendor_nearby
- order_expired
- route_progress_update (NEW)

---

## 12. Notification System (FCM)

### Events
- New order
- Order accepted
- Vendor nearby
- Order expired
- Vendor upcoming (NEW)
- Route active (NEW)

### Flow
```
App → get FCM token
→ send to backend
→ backend triggers notification
```

---

## 13. API Overview (UPDATED)

### Auth
- POST /auth/send-otp
- POST /auth/verify-otp

### Vendors
- POST /vendors/status
- POST /vendors/location
- GET /vendors/nearby

### Orders
- POST /orders
- POST /orders/:id/accept
- POST /orders/:id/reject
- POST /orders/:id/fulfill

### Routes (NEW)
- POST /seller/routes
- GET /seller/routes
- POST /seller/routes/:id/activate
- GET /seller/routes/active

---

## 14. Performance Strategy

### Must Follow
- Avoid frequent DB writes
- Use Redis for real-time
- Limit location updates
- Cache routes in Redis

---

## 15. Deployment Plan

### Steps
1. Setup VPS
2. Install Node, Nginx, Redis
3. Clone repo
4. Setup ENV
5. Run with PM2
6. Configure Nginx
7. Enable SSL

---

## 16. CI/CD Pipeline

### Flow
```
GitHub push → SSH deploy → PM2 restart
```

---

## 17. Security
- Token validation
- Rate limiting (OTP)
- Input validation
- HTTPS

---

## 18. Scaling Strategy

### Phase 1
- Single server

### Phase 2
- Separate DB + Redis

### Phase 3
- Load balancing

---

## 19. Critical Engineering Notes

### Do
- Use Redis early
- Cache routes
- Handle GPS noise

### Avoid
- Heavy DB writes
- Over-scaling early

---

## 20. Implementation Order (UPDATED)

1. Auth
2. Vendor system
3. Orders
4. Realtime
5. Notifications
6. Route system
7. Optimization

---

## 21. Final Status

System is:
- Scalable
- Real-time capable
- Route-aware
- Production-ready for MVP

---

**End of Updated Planning Document**

