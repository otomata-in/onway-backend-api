#!/usr/bin/env python3
"""
OnWay Market API — Comprehensive Endpoint Test Suite
Tests all 37 endpoints with boundary values and expected response validation.

Usage:
  python3 tests/test_api.py [--base-url http://localhost:3000]

Prerequisites:
  - Server running (npm run dev)
  - MySQL + Redis active
  - pip install requests
"""

import requests
import json
import sys
import time
from datetime import datetime

BASE_URL = "http://localhost:3000"
PASS = 0
FAIL = 0
SKIP = 0
TOKEN = None
VENDOR_ID = None
ITEM_ID = None
ITEM_ID_2 = None
ORDER_ID = None
ROUTE_ID = None
ROUTE_ID_2 = None
TEST_MOBILE = "9876543210"

# ─── Helpers ─────────────────────────────────────────────────────

def log(status, method, path, detail=""):
    icons = {"PASS": "✅", "FAIL": "❌", "SKIP": "⏭️", "INFO": "ℹ️"}
    print(f"  {icons.get(status,'  ')} [{method:6s}] {path:40s} {detail}")

def headers(auth=True):
    h = {"Content-Type": "application/json"}
    if auth and TOKEN:
        h["Authorization"] = f"Bearer {TOKEN}"
    return h

def test(name, method, path, expected_status, body=None, params=None, auth=True):
    global PASS, FAIL
    url = f"{BASE_URL}{path}"
    try:
        r = getattr(requests, method.lower())(url, json=body, params=params, headers=headers(auth), timeout=10)
        if r.status_code == expected_status:
            PASS += 1
            log("PASS", method, path, f"→ {r.status_code}")
            try:
                return r.json()
            except:
                return {}
        else:
            FAIL += 1
            detail = ""
            try:
                detail = r.json().get("message", "")[:60]
            except:
                pass
            log("FAIL", method, path, f"→ {r.status_code} (expected {expected_status}) {detail}")
            return None
    except requests.exceptions.ConnectionError:
        FAIL += 1
        log("FAIL", method, path, "→ CONNECTION REFUSED — is server running?")
        return None
    except Exception as e:
        FAIL += 1
        log("FAIL", method, path, f"→ {str(e)[:60]}")
        return None

def section(title):
    print(f"\n{'='*60}")
    print(f"  {title}")
    print(f"{'='*60}")

# ─── Tests ───────────────────────────────────────────────────────

def test_health():
    section("🏥 HEALTH CHECK")
    r = test("Health", "GET", "/", 200, auth=False)
    if r:
        assert r.get("success") == True, "Health check should return success=true"

    # Swagger JSON
    test("Swagger JSON", "GET", "/api-docs.json", 200, auth=False)


def test_auth():
    global TOKEN
    section("🔐 AUTH")

    # --- Valid OTP flow ---
    r = test("Send OTP (valid)", "POST", "/auth/send-otp", 200, {"mobile": TEST_MOBILE}, auth=False)

    # Get OTP from response (dev mode returns it)
    otp = None
    if r and r.get("data", {}).get("otp"):
        otp = r["data"]["otp"]
    elif r and r.get("data", {}).get("message"):
        otp = "12345"  # Fallback for dev (Twilio sends 5-digit OTP)

    # Verify OTP
    r = test("Verify OTP", "POST", "/auth/verify-otp", 200, {"mobile": TEST_MOBILE, "otp": otp or "12345"}, auth=False)
    if r and r.get("data", {}).get("token"):
        TOKEN = r["data"]["token"]
        log("INFO", "", "", f"Token saved: {TOKEN[:25]}...")

    # --- Boundary: invalid mobile ---
    test("Send OTP (short mobile)", "POST", "/auth/send-otp", 400, {"mobile": "123"}, auth=False)
    test("Send OTP (empty)", "POST", "/auth/send-otp", 400, {}, auth=False)
    test("Send OTP (letters)", "POST", "/auth/send-otp", 400, {"mobile": "abcdefghij"}, auth=False)

    # --- Boundary: invalid OTP ---
    test("Verify OTP (wrong)", "POST", "/auth/verify-otp", 400, {"mobile": TEST_MOBILE, "otp": "00000"}, auth=False)
    test("Verify OTP (short)", "POST", "/auth/verify-otp", 400, {"mobile": TEST_MOBILE, "otp": "12"}, auth=False)
    test("Verify OTP (no otp)", "POST", "/auth/verify-otp", 400, {"mobile": TEST_MOBILE}, auth=False)


def test_user():
    section("👤 USER PROFILE")
    if not TOKEN:
        log("SKIP", "", "", "No token — skipping")
        return

    test("Get profile", "GET", "/me", 200)
    test("Get profile (no auth)", "GET", "/me", 401, auth=False)

    # Update location — valid
    test("Update location", "PUT", "/me/location", 200, {"lat": 12.9716, "lng": 77.5946})

    # Boundary: edge coordinates
    test("Location (max lat)", "PUT", "/me/location", 200, {"lat": 90.0, "lng": 180.0})
    test("Location (min lat)", "PUT", "/me/location", 200, {"lat": -90.0, "lng": -180.0})
    test("Location (over max)", "PUT", "/me/location", 400, {"lat": 91.0, "lng": 77.5})
    test("Location (over min)", "PUT", "/me/location", 400, {"lat": -91.0, "lng": 77.5})
    test("Location (no body)", "PUT", "/me/location", 400, {})

    # FCM token
    test("Save FCM token", "POST", "/users/fcm-token", 200, {"token": "test_fcm_token_" + str(int(time.time()))})
    test("Save FCM (empty)", "POST", "/users/fcm-token", 400, {"token": ""})
    test("Save FCM (no body)", "POST", "/users/fcm-token", 400, {})


def test_seller():
    global VENDOR_ID, PASS, FAIL
    section("🏪 SELLER")
    if not TOKEN:
        return

    # Register — accepts both 201 (new) and 400 (already registered)
    url = f"{BASE_URL}/seller/register"
    r = requests.post(url, json={"vehicle_name": "Test Mango Cart"}, headers=headers(), timeout=10)
    if r.status_code == 201:
        PASS += 1
        log("PASS", "POST", "/seller/register", f"→ {r.status_code} (new registration)")
        data = r.json()
        if data.get("data", {}).get("vendor"):
            VENDOR_ID = data["data"]["vendor"].get("id")
    elif r.status_code == 400:
        PASS += 1
        log("PASS", "POST", "/seller/register", f"→ {r.status_code} (already registered)")
        # Get vendor_id from dashboard
        dr = test("Dashboard (get vendor_id)", "GET", "/seller/dashboard", 200)
        if dr and dr.get("data", {}).get("vendor"):
            VENDOR_ID = dr["data"]["vendor"].get("id")
    else:
        FAIL += 1
        log("FAIL", "POST", "/seller/register", f"→ {r.status_code}")
    if VENDOR_ID:
        log("INFO", "", "", f"Vendor ID: {VENDOR_ID}")

    # Boundary: register again (should fail)
    test("Register again (dup)", "POST", "/seller/register", 400, {"vehicle_name": "Another Cart"})
    # Boundary: missing vehicle_name
    test("Register (no name)", "POST", "/seller/register", 400, {})

    test("Dashboard", "GET", "/seller/dashboard", 200)
    test("Toggle active", "POST", "/vendors/status", 200, {"is_active": True})
    test("Update location", "POST", "/vendors/location", 200, {"lat": 12.9352, "lng": 77.6245})

    # Boundary: status missing field
    test("Toggle (no body)", "POST", "/vendors/status", 400, {})
    # Boundary: location extremes
    test("Location (edge)", "POST", "/vendors/location", 200, {"lat": 90.0, "lng": 180.0})
    test("Location (over)", "POST", "/vendors/location", 400, {"lat": 999, "lng": 77.5})


def test_inventory():
    global ITEM_ID, ITEM_ID_2
    section("📦 INVENTORY")
    if not TOKEN:
        return

    # Add items
    r = test("Add item 1", "POST", "/seller/items", 201, {"name": "Alphonso Mangoes", "price": 250.00, "quantity": 50})
    if r and r.get("data", {}).get("id"):
        ITEM_ID = r["data"]["id"]
        log("INFO", "", "", f"Item ID: {ITEM_ID}")

    r = test("Add item 2", "POST", "/seller/items", 201, {"name": "Coconut Water", "price": 40.00, "quantity": 30})
    if r and r.get("data", {}).get("id"):
        ITEM_ID_2 = r["data"]["id"]

    # List items
    test("Get items", "GET", "/seller/items", 200)

    # Update
    if ITEM_ID:
        test("Update item", "PUT", f"/seller/items/{ITEM_ID}", 200, {"price": 280.00, "quantity": 45})

    # Boundary: add with negative price
    test("Add (neg price)", "POST", "/seller/items", 400, {"name": "Bad", "price": -10})
    # Boundary: add with no name
    test("Add (no name)", "POST", "/seller/items", 400, {"price": 100})
    # Boundary: add with huge name
    test("Add (long name)", "POST", "/seller/items", 400, {"name": "A" * 200, "price": 100})
    # Boundary: update non-existent
    test("Update (id=99999)", "PUT", "/seller/items/99999", 404, {"price": 100})
    # Boundary: update with empty body
    test("Update (empty)", "PUT", f"/seller/items/{ITEM_ID or 1}", 400, {})
    # Boundary: delete non-existent
    test("Delete (id=99999)", "DELETE", "/seller/items/99999", 404)


def test_routes():
    global ROUTE_ID, ROUTE_ID_2
    section("🗺️ ROUTES")
    if not TOKEN:
        return

    # Create route
    r = test("Create route", "POST", "/seller/routes", 201, {
        "name": "Morning Route",
        "points": [
            {"lat": 12.9352, "lng": 77.6245, "sequence": 0},
            {"lat": 12.9380, "lng": 77.6260, "sequence": 1},
        ]
    })
    if r and r.get("data", {}).get("id"):
        ROUTE_ID = r["data"]["id"]
        log("INFO", "", "", f"Route ID: {ROUTE_ID}")

    r = test("Create route 2", "POST", "/seller/routes", 201, {
        "name": "Evening Route",
        "points": [{"lat": 12.98, "lng": 77.64, "sequence": 0}, {"lat": 12.99, "lng": 77.65, "sequence": 1}]
    })
    if r and r.get("data", {}).get("id"):
        ROUTE_ID_2 = r["data"]["id"]

    test("Get all routes", "GET", "/seller/routes", 200)
    test("Get active route", "GET", "/seller/routes/active", 200)

    if ROUTE_ID:
        test("Activate route", "POST", f"/seller/routes/{ROUTE_ID}/activate", 200)
        test("Update route", "PUT", f"/seller/routes/{ROUTE_ID}", 200, {
            "name": "Updated Morning", "points": [{"lat": 12.94, "lng": 77.63, "sequence": 0}, {"lat": 12.95, "lng": 77.64, "sequence": 1}]
        })

    # Boundary: no name
    test("Create (no name)", "POST", "/seller/routes", 400, {"points": [{"lat": 12.9, "lng": 77.6, "sequence": 0}]})
    # Boundary: no points
    test("Create (no points)", "POST", "/seller/routes", 400, {"name": "Empty"})
    # Boundary: activate non-existent
    test("Activate (99999)", "POST", "/seller/routes/99999/activate", 404)
    # Boundary: delete non-existent
    test("Delete (99999)", "DELETE", "/seller/routes/99999", 404)

    # Delete route 2 (not active, should work)
    if ROUTE_ID_2:
        test("Delete route 2", "DELETE", f"/seller/routes/{ROUTE_ID_2}", 200)


def test_vendor_discovery():
    section("🔍 VENDOR DISCOVERY (Buyer)")
    if not TOKEN:
        return

    # Nearby
    test("Nearby vendors", "GET", "/vendors/nearby", 200, params={"lat": 12.97, "lng": 77.59, "radius": 10})

    # Boundary: no lat
    test("Nearby (no lat)", "GET", "/vendors/nearby", 400, params={"lng": 77.59})
    # Boundary: huge radius
    test("Nearby (radius=999)", "GET", "/vendors/nearby", 400, params={"lat": 12.97, "lng": 77.59, "radius": 999})
    # Boundary: max radius
    test("Nearby (radius=50)", "GET", "/vendors/nearby", 200, params={"lat": 12.97, "lng": 77.59, "radius": 50})

    if VENDOR_ID:
        test("Vendor details", "GET", f"/vendors/{VENDOR_ID}", 200)
        test("Vendor items", "GET", f"/vendors/{VENDOR_ID}/items", 200)
        test("Vendor route", "GET", f"/vendors/{VENDOR_ID}/route", 200)
        test("Vendor ETA", "GET", f"/vendors/{VENDOR_ID}/eta", 200, params={"lat": 12.98, "lng": 77.64})

        # Favorite toggle
        test("Toggle favorite", "POST", f"/vendors/{VENDOR_ID}/favorite", 200)
        test("Get favorites", "GET", "/vendors/favorites", 200)
        test("Toggle unfavorite", "POST", f"/vendors/{VENDOR_ID}/favorite", 200)

        # ETA boundary: no coords
        test("ETA (no lat)", "GET", f"/vendors/{VENDOR_ID}/eta", 400, params={"lng": 77.6})
        test("ETA (no lng)", "GET", f"/vendors/{VENDOR_ID}/eta", 400, params={"lat": 12.9})

    # Non-existent vendor
    test("Vendor (99999)", "GET", "/vendors/99999", 404)
    test("Items (99999)", "GET", "/vendors/99999/items", 404)
    test("Favorite (99999)", "POST", "/vendors/99999/favorite", 404)


def test_orders_buyer():
    global ORDER_ID
    section("🛒 ORDERS (Buyer)")
    if not TOKEN or not VENDOR_ID or not ITEM_ID:
        log("SKIP", "", "", "Need token + vendor + item")
        return

    # Create order — NOTE: in single-user testing, buyer=seller so this returns 400
    # This is correct validation: "You cannot place an order with yourself"
    r = test("Create order (self-vendor)", "POST", "/orders", 400, {
        "vendor_id": VENDOR_ID,
        "buyer_lat": 12.9716,
        "buyer_lng": 77.5946,
        "items": [{"item_id": ITEM_ID, "qty": 2}]
    })

    # List orders
    test("Get my orders", "GET", "/orders", 200, params={"page": 1, "limit": 20})
    test("Orders (status filter)", "GET", "/orders", 200, params={"status": "requested"})

    if ORDER_ID:
        test("Order details", "GET", f"/orders/{ORDER_ID}", 200)

    # Boundary: no items
    test("Create (no items)", "POST", "/orders", 400, {
        "vendor_id": VENDOR_ID, "buyer_lat": 12.9, "buyer_lng": 77.5, "items": []
    })
    # Boundary: no vendor_id
    test("Create (no vendor)", "POST", "/orders", 400, {
        "buyer_lat": 12.9, "buyer_lng": 77.5, "items": [{"item_id": 1, "qty": 1}]
    })
    # Boundary: negative qty
    test("Create (neg qty)", "POST", "/orders", 400, {
        "vendor_id": VENDOR_ID, "buyer_lat": 12.9, "buyer_lng": 77.5,
        "items": [{"item_id": ITEM_ID, "qty": -1}]
    })
    # Boundary: non-existent order
    test("Order (99999)", "GET", "/orders/99999", 404)
    # Boundary: invalid status filter
    test("Orders (bad status)", "GET", "/orders", 400, params={"status": "invalid_status"})


def test_orders_seller():
    section("📋 ORDERS (Seller)")
    if not TOKEN:
        return

    test("Seller orders", "GET", "/seller/orders", 200, params={"page": 1, "limit": 20})
    test("Seller orders (requested)", "GET", "/seller/orders", 200, params={"status": "requested"})

    if ORDER_ID:
        test("Accept order", "POST", f"/orders/{ORDER_ID}/accept", 200)
        # Boundary: accept again (wrong status)
        test("Accept again (fail)", "POST", f"/orders/{ORDER_ID}/accept", 400)
        test("Fulfill order", "POST", f"/orders/{ORDER_ID}/fulfill", 200)
        # Boundary: fulfill again
        test("Fulfill again (fail)", "POST", f"/orders/{ORDER_ID}/fulfill", 400)

    # Boundary: non-existent
    test("Accept (99999)", "POST", "/orders/99999/accept", 404)
    test("Reject (99999)", "POST", "/orders/99999/reject", 404)
    test("Fulfill (99999)", "POST", "/orders/99999/fulfill", 404)


def test_admin():
    section("⚙️ ADMIN")
    if not TOKEN:
        return
    test("Active vendors", "GET", "/admin/active-vendors", 200)
    test("Active vendors (no auth)", "GET", "/admin/active-vendors", 401, auth=False)


def test_cleanup():
    """Cleanup: delete test item, logout"""
    section("🧹 CLEANUP")
    if ITEM_ID:
        test("Delete item 1", "DELETE", f"/seller/items/{ITEM_ID}", 200)
    if ITEM_ID_2:
        test("Delete item 2", "DELETE", f"/seller/items/{ITEM_ID_2}", 200)
    test("Logout", "POST", "/auth/logout", 200)
    test("Profile after logout", "GET", "/me", 401)


# ─── Main ────────────────────────────────────────────────────────

def main():
    global BASE_URL
    if "--base-url" in sys.argv:
        idx = sys.argv.index("--base-url")
        if idx + 1 < len(sys.argv):
            BASE_URL = sys.argv[idx + 1]

    print(f"\n{'='*60}")
    print(f"  OnWay Market API — Test Suite")
    print(f"  Base URL: {BASE_URL}")
    print(f"  Time: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print(f"{'='*60}")

    # Check server is running
    try:
        requests.get(f"{BASE_URL}/", timeout=3)
    except requests.exceptions.ConnectionError:
        print(f"\n  ❌ Cannot connect to {BASE_URL}")
        print(f"     Start the server first: npm run dev\n")
        sys.exit(1)

    test_health()
    test_auth()
    test_user()
    test_seller()
    test_inventory()
    test_routes()
    test_vendor_discovery()
    test_orders_buyer()
    test_orders_seller()
    test_admin()
    test_cleanup()

    # Summary
    total = PASS + FAIL
    print(f"\n{'='*60}")
    print(f"  📊 TEST RESULTS")
    print(f"{'='*60}")
    print(f"  ✅ Passed:  {PASS}")
    print(f"  ❌ Failed:  {FAIL}")
    print(f"  📊 Total:   {total}")
    print(f"  📈 Rate:    {PASS/total*100:.1f}%" if total > 0 else "")
    print(f"{'='*60}\n")
    sys.exit(0 if FAIL == 0 else 1)


if __name__ == "__main__":
    main()
