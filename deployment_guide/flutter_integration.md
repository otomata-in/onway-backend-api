# Flutter Applications Integration Guide

This document describes how the Flutter **Vendor** and **Buyer** apps connect to the deployed backend and how to build/distribute them for testing across remote devices.

---

## 1. Configured Base URL

Both Flutter projects have been updated to target the production cloud backend:

| Application | Configuration File | Base URL |
| :--- | :--- | :--- |
| **Vendor App** | `onway_vendor/lib/core/network/api_service.dart` | `https://onway-backend-api.onrender.com/api/v1` |
| **Buyer App** | `onway_flutter_app/lib/core/network/api_service.dart` | `https://onway-backend-api.onrender.com/api/v1` |

```dart
class VendorApiService {
  ...
  /// Live Cloud Backend URL on Render
  String baseUrl = 'https://onway-backend-api.onrender.com/api/v1';
  ...
}
```

---

## 2. Testing from Remote Devices & Locations

Because the backend is hosted with a public HTTPS endpoint and trusted SSL certificate (issued by Cloudflare / Render):
1. **No local Wi-Fi restrictions**: Testers do not need to be on the same local network or Wi-Fi as your development machine.
2. **Works on Cellular Data (4G/5G)**: Remote testers across different cities can test seamlessly on mobile data.
3. **No Android Cleartext Traffic issues**: Because the endpoint uses `https://`, Android and iOS security policies allow network requests by default without needing `usesCleartextTraffic="true"`.

---

## 3. Real-Time Features (Socket.IO)

The backend runs Socket.IO on the same port as the HTTP server.

* **Socket Endpoint**: `https://onway-backend-api.onrender.com`
* **Transport**: WebSocket (`wss://`) with HTTP Long-Polling fallback.

Render natively supports WebSockets without requiring special load balancer configurations.

---

## 4. Development Bypass Mode (OTP Verification)

To facilitate testing without incurring SMS costs from Twilio during development:
* **Endpoint**: `POST /api/v1/auth/send-otp`
* **Payload**: `{"phone": "<tester-phone-number>", "role": "BUYER" | "VENDOR"}`
* **Default Bypass OTP**: **`12345`**

Testers can enter any valid 10-digit phone number and verify with code `12345`.
Once verified, the server issues a JWT token saved in device storage (`SharedPreferences`).

---

## 5. Building the Flutter Apps for Testing

To build release or debug APKs for Android testers:

```bash
# Navigate to either app folder
cd onway_flutter_app  # or cd onway_vendor

# Clean and fetch dependencies
flutter clean
flutter pub get

# Build universal APK for testers
flutter build apk --debug  # or --release
```
The APK output is generated at:
`build/app/outputs/flutter-apk/app-debug.apk` (or `app-release.apk`).
Share this APK directly with your remote testers via Google Drive, WhatsApp, or Slack!
