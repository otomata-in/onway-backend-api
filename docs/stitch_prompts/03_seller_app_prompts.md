# 🚚 Seller App — Stitch UI Generation Prompts

> Use these highly detailed, component-level prompts in Stitch to generate pixel-perfect, world-class UI screens for the Seller App. **Note the color palette shift to Amber/Orange (#FF8F00) to distinguish from the Buyer App.**

---

### 1. Login Screen (SELLER-01)
```text
Create a modern, high-contrast Login screen for the 'OnWay Seller' app.
Background: Clean off-white (#FFF8F0 - very subtle warm tint).
Top section: A striking vector illustration of a modern vendor cart or delivery van packed with fresh goods, surrounded by a map route graphic.
Heading: Large, bold text 'Sell fresh, sell smart' in dark gray.
Subtitle: 'Enter your mobile number to access your seller dashboard'.
Main Card: White background, 24px border radius, soft drop shadow.
- Country code dropdown (+91) and phone number input field with a subtle gray border.
- A massive, full-width primary button in vibrant Amber/Orange (#FF8F00) saying 'Get Started'.
- Below the button, a pale orange info banner: 'New here? You will be registered as a seller automatically.'
The UI must feel professional, bold, and empowering for a business owner.
```

### 2. Dashboard (SELLER-02)
```text
Create the ultimate Seller Dashboard command center. It must feel like an operational cockpit.
Header: 'Welcome back, Fresh Fish Van!' with a notification bell icon (with a red dot).
HERO SECTION (The most important element):
- A massive status card taking up the top third of the screen.
- Current state: LIVE (Green theme inside this specific card).
- Big bold text '🟢 You are LIVE and visible to buyers'.
- Subtext: 'Selling for 2h 15m'.
- A gigantic, thumb-friendly toggle switch or button labeled 'Stop Selling' (in red outline).
STATS GRID (2x2 layout below the hero card):
- 4 square cards, white with subtle shadow.
- Card 1: '12' (Giant bold text), 'Orders Today' (small gray text).
- Card 2: '3' (Amber text), 'Active Orders'.
- Card 3: '9' (Green text), 'Fulfilled'.
- Card 4: '15', 'Items Listed'.
QUICK ACTIONS (Bottom list):
- '📦 View Orders' (with an amber badge showing '3')
- '📋 Manage Inventory'
- '🗺️ Route Setup'
The design must be extremely high contrast, with massive tap targets suitable for outdoor/sunlight usage.
```

### 3. Route Setup (SELLER-03)
```text
Create a highly interactive Route Creation screen for a vendor.
Top Header: Back arrow, Title 'Create Route', and an active 'Save' button in amber on the right.
Top input: A clean text field 'Route Name' pre-filled with 'Morning - Kaloor to Edappally'.
Map Area (Middle 50% of screen):
- A detailed map view.
- A green pin 'Start', two blue pins '2', '3', and a red pin 'End'.
- A dashed amber line connecting the pins in sequence.
- A floating banner at the bottom of the map: 'Tap map to add waypoints'.
Bottom Area (Waypoint List):
- A scrollable list of the added points.
- Each row: Sequence number (#1), coordinates/address text, and a drag-handle icon (☰) on the right for reordering, plus a red 'X' to delete.
The UI should beautifully blend complex map interactions with a clean, understandable list view.
```

### 4. Route Management (SELLER-04)
```text
Create a Route Management list screen.
Header: 'My Routes' with a floating action button (FAB) at the bottom right: '+ New Route' in amber.
List of Route Cards:
Card 1 (Active Route):
- White card, 4px solid green left border, elevated shadow.
- Top row: 'Morning Route - Kaloor' (bold).
- Middle row: A horizontal mini-map thumbnail (80px tall, rounded corners) showing the route polyline.
- Bottom row: '7 waypoints', a green pill badge '🟢 Active', and a gray 'Edit' icon.
Card 2 (Inactive Route):
- Flat white card, no border.
- Title: 'Evening Route - Fort Kochi'.
- Mini-map thumbnail.
- Bottom row: '4 waypoints', a gray button 'Activate Route', edit and delete icons.
Clean, structured, and easy to scan at a glance.
```

### 5. Inventory Page (SELLER-05)
```text
Create the Seller Inventory management screen.
Header: 'My Items'. Top right: '+ Add Item' button in amber.
Top summary bar: '15 total | 12 available | 3 out of stock'.
Vertical list of product cards.
Product Card (Available):
- White background, standard elevation.
- Left: 'King Fish (Ayakura)' (bold 18px). Below it: '₹450/kg' (amber color) and 'Stock: 5 kg' (gray).
- Right side: A prominent iOS-style toggle switch turned ON (green). 
- Far right: a subtle vertical '...' menu icon for edit/delete.
Product Card 2 (Out of Stock):
- Opacity reduced to 60%.
- Title: 'Tiger Prawns'.
- Toggle switch is OFF (gray).
- A red warning badge 'Sold Out'.
The design must prioritize the toggle switch, making it incredibly easy for a vendor to turn items on/off quickly.
```

### 6. Add/Edit Item (SELLER-06)
```text
Create a fast, focused 'Add New Item' bottom sheet form.
The UI is a modal sliding up from the bottom over a darkened background.
Modal top: A small drag handle pill, title 'Add New Item', and a close 'X'.
Form fields (clean, modern floating label inputs):
1. Item Name: (e.g., 'King Fish') - currently focused with a cursor.
2. Price (₹): Large numeric input field.
3. Quantity (Optional): With a dropdown for units (kg, pcs).
4. A horizontal row: 'Available to buyers immediately' with a toggle switch (ON).
Bottom: A massive, full-width amber button 'Save Item'.
The form must look highly polished, minimal, and extremely fast to fill out.
```

### 7. Start Selling Mode (SELLER-07)
```text
Create the 'Active Delivery / Live Selling' navigation screen.
This is a full-screen map view, similar to a GPS navigation app for the vendor.
Top edge: A solid, vibrant green status bar covering the safe area: '🟢 LIVE — Selling for 1h 23m' with a 'Stop' button on the right.
Map View:
- Vendor's current location is a pulsing green navigation arrow in the center.
- The active route is a thick amber polyline.
- BUYER PINS: Show 3 blue markers on the map representing buyers who have placed orders. Draw a faint 100m radius circle around each buyer pin.
Floating Bottom Sheet:
- '3 Active Orders nearby'.
- A horizontal swipeable list of order summary cards so the vendor can see who is closest.
The UI must feel like a specialized, high-tech radar/navigation tool for vendors.
```

### 8. Orders Page (SELLER-08)
```text
Create the critical Seller Orders management screen.
Header: 'Orders'. Below it, a segmented tab bar: 'Pending (2)' | 'Accepted (1)' | 'History'.
The list shows Incoming Order Cards. This is the most important card in the app.
Incoming Order Card (Pending):
- Thick amber left border, high elevation shadow.
- Top row: '#ORD-15' and timestamp 'Just now'.
- Middle row: 'Buyer is 450m away' (with a compass arrow pointing North-East).
- Items: 'King Fish x2, Prawns x1' (bold).
- Total: '₹1,250'.
- Bottom row (Massive Actions): Two huge buttons side-by-side. Left: '❌ Reject' (red outline, 30% width). Right: '✅ Accept Order' (solid green, 70% width).
Accepted Order Card:
- Thick green left border.
- Bottom action: A single massive solid green button '🎉 Mark Fulfilled'.
The cards must be large, hyper-legible, and impossible to tap incorrectly.
```

### 9. Active Delivery Mode (SELLER-09)
```text
Create a focused 'Drive & Deliver' screen for the vendor.
Top 60% of screen: 3D-tilted navigation map. Thick route line. Prominent marker showing 'Next Stop: 200m'.
Bottom 40% of screen: A rigid, non-scrollable 'Up Next' panel.
Inside the panel:
- Large header: 'Next Buyer: #ORD-15'.
- Distance: '200 meters away' (Live updating typography).
- Order summary: 'King Fish x2'.
- A massive, edge-to-edge swipe button (Swipe to Fulfill) in bright green. 'Slide to mark delivered >>'.
This UI is built for extreme safety and glanceability while driving or riding a cart. Zero clutter, massive fonts.
```

### 10. Fulfillment Screen (SELLER-10)
```text
Create a Success/Confirmation screen for fulfilling an order.
Background: Solid white.
Center screen: A large, beautifully animated green checkmark or celebration icon (🎉).
Large text: 'Order #ORD-15 Fulfilled!'
Subtitle: 'Transaction complete. The buyer has been notified.'
A receipt card in the center:
- Buyer: +91 98***43210
- Items: 3
- Total Value: ₹1,250
Bottom: A large amber button 'Back to Orders'.
The screen should feel incredibly rewarding, clean, and satisfying.
```

### 11. Notifications (SELLER-11)
```text
Create the Seller Notifications screen.
Header: 'Alerts & Updates'.
Notification Card 1 (High Priority):
- Pale amber background.
- Left icon: 🛒 in an amber circle.
- Bold Title: 'New Order Received!'.
- Body: 'Order #ORD-16 for ₹900. Buyer is 300m away.'
- Action: Inline button 'View Order'.
Notification Card 2:
- White background.
- Left icon: ⏰ (gray).
- Title: 'Order Expired'.
- Body: 'Order #ORD-12 expired because you passed the buyer's location.'
Focus on clear typography, ample whitespace, and distinct visual hierarchy for high-priority alerts versus informational ones.
```
