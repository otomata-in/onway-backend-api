# OnWay Market — Product & Frontend Specification

---

# 1. Project Concept

OnWay Market is a **real-time hyperlocal mobile marketplace** that connects buyers with **moving street vendors** (fish sellers, vegetable carts, meat vans, etc.).

Unlike traditional marketplaces, vendors are **not stationary** — they move through neighborhoods, and users can:

- Discover nearby vendors in real time
- Track their movement
- Place **intent-based order tokens**
- Get notified when vendors are nearby

---

# 2. Project Purpose

## Core Goals

- Digitize informal street vending ecosystem
- Improve accessibility to fresh products
- Reduce uncertainty for buyers
- Help vendors increase sales efficiency

## Key Value

- Buyers know **when a vendor is coming**
- Vendors know **who is interested in buying**
- No strict logistics or delivery complexity

---

# 3. Product Philosophy

- Not a delivery app
- Not a guaranteed order system
- A **real-time interaction platform between moving sellers and local buyers**

---

# 4. Application Overview

There are **two mobile applications**:

## 1. Buyer App
- For customers
- Discover and interact with vendors

## 2. Seller App
- For vendors
- Manage selling, routes, and requests

---

# 5. BUYER APP — COMPLETE FLOW

```
Login → Home Map → Vendor Discovery → Vendor Details
→ Place Order Token → Live Tracking → Notification → Completion
```

---

# 6. BUYER APP — SCREENS & FEATURES

---

## 6.1 Login Screen

### Features:
- Enter mobile number
- OTP-based authentication

---

## 6.2 OTP Verification Screen

### Features:
- Enter OTP
- Auto verification

---

## 6.3 Home Screen (Live Map)

### Features:
- Map view with live vendors
- Vendor markers
- Category filters
- Regular vendors section
- Search

---

## 6.4 Vendor List / Card View

### Features:
- Vendor name
- Distance
- ETA
- Category (fish, vegetables, etc.)

---

## 6.5 Vendor Details Page

### Features:
- Vendor info
- Items list
- Prices
- Availability

---

## 6.6 Order Token Page

### Features:
- Select items
- Set quantity
- Confirm token request

---

## 6.7 Live Tracking Page

### Features:
- Vendor live movement
- Route visualization (if available)
- ETA display

---

## 6.8 Notification Handling

### Features:
- Vendor nearby alert
- Order status updates

---

## 6.9 Orders / History Page

### Features:
- Active tokens
- Past orders
- Reorder option

---

## 6.10 Profile / Settings

### Features:
- Saved locations
- Notification settings
- Language

---

# 7. SELLER APP — COMPLETE FLOW

```
Login → Dashboard → Setup Route → Add Items → Start Selling
→ Receive Orders → Move → Fulfill → Continue / Stop
```

---

# 8. SELLER APP — SCREENS & FEATURES

---

## 8.1 Login Screen

### Features:
- Mobile OTP login

---

## 8.2 Dashboard

### Features:
- Start / Stop selling
- Active orders count
- Earnings (optional)
- Quick navigation

---

## 8.3 Route Setup Screen (CORE FEATURE)

### Features:
- Select start point
- Select end point
- Add multiple waypoints
- Save route
- Activate route

---

## 8.4 Route Management Screen

### Features:
- View saved routes
- Activate route
- Delete/edit routes

---

## 8.5 Inventory Page

### Features:
- View items
- Update stock
- Toggle availability

---

## 8.6 Add / Edit Item Page

### Features:
- Item name
- Price
- Quantity
- Category

---

## 8.7 Start Selling Mode

### Features:
- Enable visibility on map
- Start GPS tracking
- Activate route tracking

---

## 8.8 Orders Page

### Features:
- Incoming order tokens
- Accept / Reject
- View buyer details

---

## 8.9 Active Delivery Mode

### Features:
- Route navigation
- Track nearby buyers
- Order priority based on distance

---

## 8.10 Fulfillment Screen

### Features:
- Mark order fulfilled

---

## 8.11 Notifications

### Features:
- New order alert
- Route-based demand insights

---

# 9. CORE SYSTEM FEATURES

---

## 9.1 Real-Time Tracking
- Live vendor location
- Socket-based updates

---

## 9.2 Route-Based Selling (Unique Feature)
- Predefined vendor routes
- Waypoints
- Route prediction

---

## 9.3 Order Token System
- Non-guaranteed orders
- Intent-based requests

---

## 9.4 Proximity Detection
- Notify when vendor is within 100m
- Expire when vendor leaves area

---

## 9.5 Push Notifications
- Vendor nearby
- Order updates

---

# 10. USER EXPERIENCE PRINCIPLES

- Simple for non-technical vendors
- Fast interaction
- Real-time feedback
- Minimal friction

---

# 11. FINAL PRODUCT VISION

OnWay Market is not just a marketplace — it is a:

> **Route-aware, real-time, intent-based local commerce system**

---

# END O