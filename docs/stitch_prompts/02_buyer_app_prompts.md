# 🛒 Buyer App — Stitch UI Generation Prompts

> Use these highly detailed, component-level prompts in Stitch to generate pixel-perfect, world-class UI screens for the Buyer App.

---

### 1. Login Screen (BUYER-01)
```text
Create a premium, modern mobile Login screen for 'OnWay', a hyperlocal fresh food marketplace. 
The background should be a clean off-white (#F8FAF8).
At the top, include a beautiful, high-quality vector illustration or 3D render of a fresh food delivery van driving through a minimal neighborhood.
Below the illustration, a large bold heading 'Fresh food, straight to your door' in Inter font, dark green text.
Below that, a subtle subtitle 'Enter your mobile number to get started'.
The main interaction area is a white card with 24px border radius and a soft drop shadow. 
Inside the card:
- A modern phone number input field. The left side should have a country code dropdown (+91) with a subtle gray background. The right side is the number input.
- A large, full-width, pill-shaped primary button (color: #2E7D32) saying 'Get Started' in bold white text.
- Below the button, small muted text: 'By continuing, you agree to our Terms & Privacy Policy'.
Ensure generous padding (24px) around all elements. The design must feel trustworthy, smooth, and consumer-friendly.
```

### 2. OTP Verification (BUYER-02)
```text
Create a sleek OTP Verification mobile screen.
Top left: a minimal back arrow icon.
Header: Large bold text 'Verify your number'. Subtitle below it: 'Enter the 6-digit code sent to +91 98765 43210'.
In the center, create a row of 6 large, distinct input boxes for the OTP. Each box should be 48x56px, rounded corners (12px), with a subtle gray border and very light green background for the active/focused box.
Below the inputs, a centered countdown timer in primary green: '00:45'.
Below that, a muted text 'Didn't receive the code?' with a bold green 'Resend' link.
At the absolute bottom of the screen, a full-width green primary button 'Verify & Continue' with 16px border radius, placed with safe area padding.
The aesthetic is clean, distraction-free, and highly polished.
```

### 3. Home Screen / Live Map (BUYER-03)
```text
Create a world-class, premium mobile Home Screen featuring an edge-to-edge 3D isometric map UI.
The background of the top 60% of the screen is a detailed 3D isometric light-mode map with buildings, roads, and trees.
Top Header (Floating over map):
- Left: Circular back arrow button.
- Center: App logo 'OnWay Market' with a green map pin icon containing a delivery cart.
- Right: A language selector pill 'EN ˅'.
Below Header:
- A full-width, pill-shaped white search bar with a magnifying glass icon, placeholder text 'Search for vendors, items...', a vertical divider, and a filter icon on the right. Soft drop shadow.
Map Elements (Floating):
- Small pill buttons: '🟢 LIVE: Scanning area...' and '📶 FILTERS'.
- Vendor Map Markers: Designed as floating white pill cards. 
  - Card 1: Green 'LIVE' badge, 'Fish Van', '400 m', 'ETA ₹300/kg', and a tiny image of a blue van. A right-pointing arrow button.
  - Card 2: 'Veggies & Fruits Truck', 'ETA 4 min', and a tiny image of fresh produce.
- User Location: Green pins labeled 'my home' with dashed green route lines connecting to vendors.
Bottom Sheet (Overlaying the bottom 50% of the screen):
- A large white panel with rounded top corners and a drag handle indicator at the top center. The top edge blends softly with the map using a glassmorphic gradient.
- Categories Section: Header 'Categories' on the left, 'All Live >' on the right. Below it, a horizontally scrolling row of white pill-shaped category chips with soft shadows: '🐟 Fish', '🥬 Vegetables', '🥩 Meat'.
- Nearby Vendors Section: Header 'Nearby Vendors'. Below it, a vertical list of vendor cards.
- Vendor Card Design: White background, soft shadow, highly rounded corners. 
  - Left: A high-quality cutout image of a delivery truck (e.g., a green truck loaded with produce).
  - Middle: Vendor Name (e.g., 'Fresh Meat Van' in bold), subtitle 'ETA ₹5 mins'.
  - Right: 'Live 🟢' status text, and a prominent solid green button labeled 'View & Request' with fully rounded corners (pill shape).
Bottom Navigation Bar:
- White background, 4 tabs: 'Home' (Green, active, house icon), 'Categories' (gray outline icon), 'Orders' (gray list icon), 'Account' (gray user icon). 
The overall aesthetic must be ultra-premium, spatial, and highly polished iOS design. Use primary color #2E7D32 (Forest Green).
```

### 4. Vendor List View (BUYER-04)
```text
Create a beautiful Vendor List View screen (an alternative to the map).
Header: 'Nearby Vendors' in large bold typography. Top right: a map icon button to switch views.
Below header: The same horizontal row of category pills as the home screen (Fish, Veggies, Meat).
Below categories: A vertical list of stunning Vendor Cards.
Each Vendor Card should look like a premium UI component:
- White background, 16px border radius, soft elevation.
- Left side: A beautiful 80x80px rounded image of fresh produce or a vendor cart.
- Right side: 
  - Top row: Vendor Name (bold) and a green 'LIVE' badge.
  - Middle row: Muted text 'Fresh Sea Fish & Prawns'.
  - Bottom row: A location icon with '450m away' and a clock icon with 'est. 5 mins'. 
  - A subtle right arrow icon (>) on the far right edge to indicate tappability.
Ensure perfect alignment, 16px gaps between cards, and a highly scannable, clean layout.
```

### 5. Vendor Details Page (BUYER-05)
```text
Create a comprehensive Vendor Details mobile screen.
TOP: An edge-to-edge cover image showing fresh fish on ice (height: 200px). A floating circular back button in the top left.
OVERLAPPING THE IMAGE: A large white card that pulls up over the bottom 40px of the image, with 24px top rounded corners.
Inside this card (Header section): 
- Vendor Name 'Ocean Fresh Mobile' in large bold H1.
- Below it, a row of stats: ⭐ 4.8 | 📍 450m away | ⏱️ 5 mins ETA.
- A mini-map widget (100px height, rounded corners) showing a small route line from the vendor to the user.
BODY SECTION (Scrollable):
- A bold subheader 'Available Today'.
- A vertical list of product items.
- Product Item row: 
  - Left: Item Name 'King Fish (Ayakura)', Price '₹450 / kg', and small green text 'In Stock'.
  - Right: A beautifully designed Add/Quantity stepper. If 0, it's a primary green button 'Add'. If >0, it's a pill shape with [-] [ 2 ] [+].
BOTTOM: A sticky bottom bar with a strong drop shadow. It shows '2 items | ₹900' on the left, and a large green 'Create Order Token →' button on the right.
```

### 6. Order Token Page (BUYER-06)
```text
Create a Checkout / Order Token screen.
Header: Back arrow and title 'Review Order'.
Section 1 (Vendor Info): A card showing 'Ordering from Ocean Fresh Mobile', with their live distance 'Currently 450m away'.
Section 2 (Order Summary): A clean white card listing the selected items. 
- 2x King Fish (₹900)
- 1x Prawns (₹350)
- A dotted divider line.
- Total Estimate: ₹1,250. 
Below the total, a muted disclaimer: '(Final price may vary slightly based on exact weight)'.
Section 3 (How it works warning): A pale amber/yellow information box with an info icon. Text: 'This is an order token, not a final payment. The vendor will hold these items for you. Pay directly when they arrive.'
BOTTOM ACTION: A massive, full-width, dark green button 'Submit Order Token'. Make the UI feel highly secure, clear, and transactional.
```

### 7. Live Tracking Page (BUYER-07)
```text
Create a highly dynamic Live Tracking screen. This is the 'Uber-style' map tracking view.
The screen is 100% full-bleed map.
Map elements:
- A prominent vendor marker (a van icon) placed on a road.
- A blue dot for the buyer's location.
- A dashed line (route) connecting the vendor to the buyer.
- A massive, eye-catching Proximity Banner floating at the top of the screen. Bright green background, bold white text: '🎉 Vendor is nearby! (~100m away)'.
Bottom Sheet (Floating above the map):
- 24px rounded top corners, pure white.
- Giant ETA text: '2 mins away' (primary green, extra bold 32px font).
- Subtitle: 'Ocean Fresh Mobile is approaching'.
- Order Status row: A timeline with 3 dots (Requested [green] -> Accepted [green] -> Arriving [pulsing green]).
- Bottom of the sheet: Two buttons side-by-side. A gray button '📞 Call Vendor' and a primary button 'View Order Details'.
The design must convey real-time movement and excitement.
```

### 8. Notifications (BUYER-08)
```text
Create a clean Notifications screen for the buyer app.
Header: 'Notifications' with a 'Mark all read' text button on the right.
A vertical list of notification cards.
Notification Card 1 (Unread): Very pale blue/green background. 
- Left: A circular icon container with a 📍 map pin emoji.
- Body: Title 'Vendor is Nearby!' (bold). Subtext: 'Ocean Fresh Mobile is 85m away from you. Get ready!'. Time: 'Just now'.
- Right: A small blue unread dot.
Notification Card 2 (Read): White background.
- Left: A circular icon container with a ✅ checkmark.
- Body: Title 'Order Accepted'. Subtext: 'Your order for King Fish has been accepted.' Time: '10 mins ago'.
Notification Card 3 (Read): White background.
- Left: A 🎉 party popper icon.
- Body: Title 'Order Complete'. Subtext: 'Thank you for buying from Ocean Fresh!' Time: 'Yesterday'.
Use generous spacing, highly legible fonts, and a premium minimal aesthetic.
```

### 9. Orders / History (BUYER-09)
```text
Create the 'My Orders' screen.
Header: Large title 'My Orders'.
Below header: A modern segmented control (tab bar) with two options: 'Active Orders' (selected, green background pill) and 'History'.
Body: A list of Active Order cards.
Active Order Card design:
- White background, elevated shadow (feels interactive).
- Top row: Order ID '#ORD-15' (gray) and a bright yellow status pill '⏳ Accepted - On the way'.
- Middle row: Vendor name 'Ocean Fresh Mobile' (bold 18px), and item summary 'King Fish x2, Prawns x1' (gray).
- Bottom row: Estimated total '₹1,250' and a primary green outlined button 'Track Vendor →'.
History Order Card (show one below for context):
- Flatter, less shadow.
- Status pill is green '🎉 Fulfilled'.
- Bottom row has a gray button 'Order Again'.
The UI should be heavily structured, grid-aligned, and extremely easy to read.
```

### 10. Profile & Settings (BUYER-10)
```text
Create a beautifully structured Profile and Settings screen.
Header area: 
- A large circular avatar (initials 'AV' on a green gradient background).
- User's mobile number '+91 98765 43210' in bold H2.
- A small green pill badge 'Buyer'.
First Section (Card layout): 'Start Selling'
- A vibrant, premium gradient card (Orange/Amber gradient) inside the buyer app. 
- Text: 'Own a van? Start selling on OnWay'
- Button: 'Become a Seller' in white. This should be the most attractive element on the screen.
Second Section (List items): 'Saved Locations'
- '🏠 Home' (Subtext: 123 Main St, Kochi)
- '🏢 Work' (Subtext: InfoPark, Kochi)
Third Section (List items): 'Preferences'
- '🔔 Push Notifications' (with a green iOS-style toggle switch turned ON).
- '🌐 Language' (Subtext: English).
Bottom: A red text button 'Log Out'.
Use 16px corner radii for all cards and sections, with a light gray app background to make the white sections pop.
```
