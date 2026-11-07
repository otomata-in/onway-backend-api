# 🎨 OnWay Market — Stitch UI Foundation & Design System

> These prompts are designed to configure the foundational Design System in Stitch. You can use this markdown directly as the `DESIGN.md` when creating a Stitch Design System for the OnWay Market apps.

---

## 1. Buyer App — Foundation Theme (DESIGN.md)

Copy and paste this into the Stitch Design System configuration for the **Buyer App**.

```markdown
# OnWay Market Buyer App - Premium Design System

## 1. Core Aesthetics & Philosophy
- **Style**: Ultra-modern, clean, minimal, and premium.
- **Theme**: Light mode optimized (fresh, organic feel).
- **Vibe**: Hyperlocal, fast, trustworthy, and eco-friendly.
- **Key Visuals**: Glassmorphism (blur effects) on floating panels over maps, soft layered shadows, and edge-to-edge imagery/maps.

## 2. Color Palette
- **Primary**: `#2E7D32` (Vibrant Forest Green) — used for primary actions, active states, and success.
- **Primary Container**: `#E8F5E9` (Very light green) — used for subtle highlights and card backgrounds.
- **Secondary**: `#81C784` (Soft Green) — used for secondary accents.
- **Surface**: `#FFFFFF` (Pure White) — main background for cards and bottom sheets.
- **Background**: `#F8FAF8` (Off-white/light gray) — main app background.
- **Text Primary**: `#1A1C19` (Near Black) — high contrast reading.
- **Text Secondary**: `#737970` (Muted Gray).
- **Alert/Warning**: `#FFA726` (Amber) for pending/waiting states.
- **Error/Destructive**: `#D32F2F` (Crimson) for errors and rejections.

## 3. Typography
- **Font Family**: `Inter`, `Outfit`, or `Plus Jakarta Sans`.
- **Headings**: Bold, tight letter spacing (tracking-tight).
- **Body**: Regular, readable line height (leading-relaxed).
- **Numbers/Prices**: Use a monospaced or tabular numbers font feature if possible, always bold.

## 4. UI Elements & Shapes
- **Corner Radius (Border Radius)**:
  - Cards & Bottom Sheets: `24px` (Very rounded, modern iOS style).
  - Buttons: `16px` (Pill-like or fully rounded).
  - Badges/Tags: `999px` (Fully rounded pills).
- **Shadows & Elevation**:
  - Floating elements (FABs, bottom sheets over maps) must use a soft, large shadow: `0 20px 40px rgba(0,0,0,0.08)`.
  - Standard cards use subtle elevation: `0 4px 12px rgba(0,0,0,0.04)`.
- **Borders**: Avoid harsh borders. Use very light borders (`#E0E5E0`) only when separating similar white surfaces.

## 5. Map Integration Rules
- Maps should always be edge-to-edge (full bleed).
- UI elements placed over maps (search bars, vendor cards, FABs) MUST have a glassmorphism effect: `backdrop-filter: blur(12px)` with a semi-transparent white background `rgba(255, 255, 255, 0.85)`.
```

---

## 2. Seller App — Foundation Theme (DESIGN.md)

Copy and paste this into the Stitch Design System configuration for the **Seller App**.

```markdown
# OnWay Market Seller App - Command Center Design System

## 1. Core Aesthetics & Philosophy
- **Style**: Utilitarian, high-contrast, bold, and highly legible outdoors.
- **Theme**: High-visibility (built for street vendors in bright sunlight).
- **Vibe**: Professional, urgent, reliable, and actionable.
- **Key Visuals**: Large tap targets, bold status indicators, clear hierarchy, zero clutter.

## 2. Color Palette
- **Primary**: `#FF8F00` (Vibrant Amber/Orange) — used for brand identity and primary actions.
- **Primary Container**: `#FFF3E0` (Very light orange) — highlights and active states.
- **Surface**: `#FFFFFF` (Pure White).
- **Background**: `#F9F9F9` (Light gray) — to make white cards pop.
- **Text Primary**: `#212121` (High contrast Dark Gray).
- **Text Secondary**: `#757575` (Medium Gray).
- **Status LIVE / Success**: `#43A047` (Vibrant Green) — critical for "Start Selling" state.
- **Status OFFLINE / Error**: `#E53935` (Bright Red) — critical for "Stop Selling" state.

## 3. Typography
- **Font Family**: `Roboto` or `Inter`.
- **Scale**: Up-scaled by 10% compared to typical apps. Minimum tap target size text should be 16px.
- **Weights**: Heavy use of Semibold and Bold for stats and actions.

## 4. UI Elements & Shapes
- **Corner Radius (Border Radius)**:
  - Cards & Modals: `16px` (Slightly more structured than the buyer app).
  - Buttons: `12px` (Chunky and solid).
- **Shadows**:
  - High elevation for critical alerts (New Order incoming).
  - Flat design for standard list items.
- **Interactions**:
  - Critical actions (Accept/Reject/Go Live) must be massive, full-width buttons.
```

---

## 3. Stitch Prompting Guide: "The Perfect UI Formula"

When generating individual screens in Stitch, use this formula to ensure world-class results:

1. **Role Context**: "You are an expert UI/UX designer creating a premium mobile app screen."
2. **Screen Purpose**: "This is the [Screen Name], its primary goal is to [Goal]."
3. **Layout Structure**: Define the top, middle, and bottom sections clearly.
4. **Visual Polish Requests**: Explicitly ask for "beautiful spacing", "modern typography", "glassmorphism", and "clear visual hierarchy".
5. **Data Population**: Provide high-quality, realistic dummy data (e.g., "Fresh King Fish", not "Item A").
