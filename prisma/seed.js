require('dotenv').config();
const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  console.log('🌱 Starting OnWay Market Database Seeding for Perumbilavu, Thrissur...');

  // 1. Fetch existing user +918848793417
  const existingUser = await prisma.user.findUnique({
    where: { phone: '+918848793417' },
    include: { buyerProfile: { include: { addresses: true } } }
  });

  console.log('🧹 Cleaning up dependent vendor/order/booking tables...');
  await prisma.bookingItem.deleteMany();
  await prisma.booking.deleteMany();
  await prisma.orderItem.deleteMany();
  await prisma.orderEnquiry.deleteMany();
  await prisma.liveVendorLocation.deleteMany();
  await prisma.routeWaypoint.deleteMany();
  await prisma.sellingRoute.deleteMany();
  await prisma.inventoryProduct.deleteMany();
  await prisma.vendorReview.deleteMany();
  await prisma.dailyTracking.deleteMany();
  await prisma.buyerFavorite.deleteMany();
  await prisma.notification.deleteMany();
  await prisma.twilioOtpLog.deleteMany();

  // Delete other non-primary users/profiles
  await prisma.buyerAddress.deleteMany();
  await prisma.vendorProfile.deleteMany();
  await prisma.buyerProfile.deleteMany();
  await prisma.user.deleteMany();

  console.log('✅ Dependent tables cleaned up.');

  // ─── 2. SEED BUYER USER (+91 8848793417) WITH PERUMBILAVU THRISSUR ADDRESS ───
  const buyerUser = await prisma.user.create({
    data: {
      phone: '+918848793417',
      role: 'BUYER',
      isVerified: true,
      buyerProfile: {
        create: {
          fullName: 'AKHIL V A',
          latitude: 10.698731,
          longitude: 76.091942,
          pushNotifications: true,
          darkMode: false,
          language: 'English',
          addresses: {
            create: [
              {
                title: 'Perumbilavu Office / Home',
                addressLine: 'Perumbilavu Junction, Highway Road, Perumbilavu, Thrissur, Kerala, 680519, India',
                latitude: 10.698731,
                longitude: 76.091942,
                isDefault: true,
              },
              {
                title: 'Mattom Home',
                addressLine: 'Mattom, Kunnamkulam, Thrissur, Kerala, 680104, India',
                latitude: 10.59337,
                longitude: 76.080334,
                isDefault: false,
              }
            ]
          }
        }
      }
    },
    include: { buyerProfile: { include: { addresses: true } } }
  });

  console.log('✅ Created Buyer User +918848793417 with Perumbilavu address.');
  const buyerProfileId = buyerUser.buyerProfile.id;

  // ─── 3. SEED 5 LIVE VENDORS IN PERUMBILAVU, THRISSUR (10.698731, 76.091942) ───

  // Vendor 1: Perumbilavu Fresh Organic Veggies (+91 9349523779)
  const v1User = await prisma.user.create({
    data: {
      phone: '+919349523779',
      role: 'VENDOR',
      isVerified: true,
      vendorProfile: {
        create: {
          businessName: 'Perumbilavu Fresh Organic Veggies',
          vehicleNumber: 'KL-46-BW-1008',
          category: 'Organic Vegetables',
          operatingHours: '7:00 AM - 7:00 PM Daily',
          rating: 4.9,
          isLiveBroadcasting: true,
          isDeliveryMode: true,
          currentLatitude: 10.6990,
          currentLongitude: 76.0925,
        }
      }
    },
    include: { vendorProfile: true }
  });

  // Vendor 2: Perumbilavu Malabar Dairy & Fresh Milk (+91 9895001122)
  const v2User = await prisma.user.create({
    data: {
      phone: '+919895001122',
      role: 'VENDOR',
      isVerified: true,
      vendorProfile: {
        create: {
          businessName: 'Perumbilavu Malabar Dairy & Fresh Milk',
          vehicleNumber: 'KL-46-AZ-5544',
          category: 'Dairy & Farm Produce',
          operatingHours: '6:30 AM - 7:30 PM Daily',
          rating: 4.8,
          isLiveBroadcasting: true,
          isDeliveryMode: true,
          currentLatitude: 10.6975,
          currentLongitude: 76.0905,
        }
      }
    },
    include: { vendorProfile: true }
  });

  // Vendor 3: Thrissur Highway Fruit Mart (+91 9447003344)
  const v3User = await prisma.user.create({
    data: {
      phone: '+919447003344',
      role: 'VENDOR',
      isVerified: true,
      vendorProfile: {
        create: {
          businessName: 'Thrissur Highway Fruit Mart',
          vehicleNumber: 'KL-46-XY-9988',
          category: 'Fresh Fruits',
          operatingHours: '6:00 AM - 8:00 PM Daily',
          rating: 4.7,
          isLiveBroadcasting: true,
          isDeliveryMode: true,
          currentLatitude: 10.7005,
          currentLongitude: 76.0935,
        }
      }
    },
    include: { vendorProfile: true }
  });

  // Vendor 4: Perumbilavu Coast Fish & Seafood (+91 9633243366)
  const v4User = await prisma.user.create({
    data: {
      phone: '+919633243366',
      role: 'VENDOR',
      isVerified: true,
      vendorProfile: {
        create: {
          businessName: 'Perumbilavu Coast Fish & Seafood',
          vehicleNumber: 'KL-46-CV-2026',
          category: 'Fresh Fish & Seafood',
          operatingHours: '7:30 AM - 6:00 PM Daily',
          rating: 4.9,
          isLiveBroadcasting: true,
          isDeliveryMode: true,
          currentLatitude: 10.6965,
          currentLongitude: 76.0890,
        }
      }
    },
    include: { vendorProfile: true }
  });

  // Vendor 5: Perumbilavu Bakes & Snacks (+91 6235273779)
  const v5User = await prisma.user.create({
    data: {
      phone: '+916235273779',
      role: 'VENDOR',
      isVerified: true,
      vendorProfile: {
        create: {
          businessName: 'Perumbilavu Bakes & Snacks',
          vehicleNumber: 'KL-46-BK-3040',
          category: 'Bakery & Snacks',
          operatingHours: '8:00 AM - 9:00 PM Daily',
          rating: 4.8,
          isLiveBroadcasting: true,
          isDeliveryMode: false,
          currentLatitude: 10.6995,
          currentLongitude: 76.0910,
        }
      }
    },
    include: { vendorProfile: true }
  });

  console.log('✅ 5 Live Vendors created in Perumbilavu, Thrissur.');

  // ─── 4. SEED INVENTORY PRODUCTS FOR ALL VENDORS ───

  // Products for Vendor 1 (Perumbilavu Fresh Organic Veggies)
  const p1 = await prisma.inventoryProduct.create({
    data: {
      vendorId: v1User.vendorProfile.id,
      name: 'Organic Red Tomatoes',
      category: 'Vegetables',
      price: 0.0,
      unit: 'kg',
      inStock: true,
      stockLevel: 'GOOD',
      imagePath: 'assets/images/vegetables.png',
    }
  });

  const p2 = await prisma.inventoryProduct.create({
    data: {
      vendorId: v1User.vendorProfile.id,
      name: 'Nendran Bananas',
      category: 'Fruits',
      price: 0.0,
      unit: 'kg',
      inStock: true,
      stockLevel: 'GOOD',
      imagePath: 'assets/images/vegetables.png',
    }
  });

  await prisma.inventoryProduct.createMany({
    data: [
      { vendorId: v1User.vendorProfile.id, name: 'Kerala Yam (Chena)', category: 'Vegetables', price: 0.0, unit: 'kg', inStock: true, stockLevel: 'GOOD', imagePath: 'assets/images/vegetables.png' },
      { vendorId: v1User.vendorProfile.id, name: 'Tapioca (Kappa)', category: 'Vegetables', price: 0.0, unit: 'kg', inStock: true, stockLevel: 'GOOD', imagePath: 'assets/images/vegetables.png' },
      { vendorId: v1User.vendorProfile.id, name: 'Fresh Tender Coconut Water', category: 'Beverages', price: 0.0, unit: 'piece', inStock: true, stockLevel: 'GOOD', imagePath: 'assets/images/vegetables.png' },
    ]
  });

  // Products for Vendor 2 (Perumbilavu Malabar Dairy)
  await prisma.inventoryProduct.createMany({
    data: [
      { vendorId: v2User.vendorProfile.id, name: 'Pure Cow Milk', category: 'Dairy', price: 0.0, unit: 'liter', inStock: true, stockLevel: 'GOOD', imagePath: 'assets/images/vegetables.png' },
      { vendorId: v2User.vendorProfile.id, name: 'Farm Cow Ghee', category: 'Dairy', price: 0.0, unit: 'kg', inStock: true, stockLevel: 'GOOD', imagePath: 'assets/images/vegetables.png' },
      { vendorId: v2User.vendorProfile.id, name: 'Fresh Buffalo Curd', category: 'Dairy', price: 0.0, unit: 'kg', inStock: true, stockLevel: 'GOOD', imagePath: 'assets/images/vegetables.png' },
    ]
  });

  // Products for Vendor 3 (Thrissur Highway Fruit Mart)
  await prisma.inventoryProduct.createMany({
    data: [
      { vendorId: v3User.vendorProfile.id, name: 'Alphonso Mangoes', category: 'Fruits', price: 0.0, unit: 'kg', inStock: true, stockLevel: 'GOOD', imagePath: 'assets/images/vegetables.png' },
      { vendorId: v3User.vendorProfile.id, name: 'Sweet Farm Papaya', category: 'Fruits', price: 0.0, unit: 'kg', inStock: true, stockLevel: 'GOOD', imagePath: 'assets/images/vegetables.png' },
      { vendorId: v3User.vendorProfile.id, name: 'Ripe Jackfruit (Chakka)', category: 'Fruits', price: 0.0, unit: 'kg', inStock: true, stockLevel: 'GOOD', imagePath: 'assets/images/vegetables.png' },
    ]
  });

  // Products for Vendor 4 (Perumbilavu Coast Fish)
  await prisma.inventoryProduct.createMany({
    data: [
      { vendorId: v4User.vendorProfile.id, name: 'Pearl Spot (Karimeen)', category: 'Seafood', price: 0.0, unit: 'kg', inStock: true, stockLevel: 'GOOD', imagePath: 'assets/images/vegetables.png' },
      { vendorId: v4User.vendorProfile.id, name: 'Kingfish (Ayakoora)', category: 'Seafood', price: 0.0, unit: 'kg', inStock: true, stockLevel: 'GOOD', imagePath: 'assets/images/vegetables.png' },
      { vendorId: v4User.vendorProfile.id, name: 'Fresh Prawns (Chemmeen)', category: 'Seafood', price: 0.0, unit: 'kg', inStock: true, stockLevel: 'GOOD', imagePath: 'assets/images/vegetables.png' },
    ]
  });

  // Products for Vendor 5 (Perumbilavu Bakes)
  await prisma.inventoryProduct.createMany({
    data: [
      { vendorId: v5User.vendorProfile.id, name: 'Fresh Wheat Bread', category: 'Bakery', price: 0.0, unit: 'packet', inStock: true, stockLevel: 'GOOD', imagePath: 'assets/images/vegetables.png' },
      { vendorId: v5User.vendorProfile.id, name: 'Banana Chips (Upperi)', category: 'Snacks', price: 0.0, unit: 'kg', inStock: true, stockLevel: 'GOOD', imagePath: 'assets/images/vegetables.png' },
      { vendorId: v5User.vendorProfile.id, name: 'Traditional Unniyappam', category: 'Snacks', price: 0.0, unit: 'box', inStock: true, stockLevel: 'GOOD', imagePath: 'assets/images/vegetables.png' },
    ]
  });

  console.log('✅ Inventory Products seeded for all 5 Perumbilavu vendors.');

  // ─── 5. SEED SELLING ROUTES & WAYPOINTS FOR ALL VENDORS ───
  await prisma.sellingRoute.create({
    data: {
      vendorId: v1User.vendorProfile.id,
      name: 'Perumbilavu Highway Express Route',
      description: '4 Waypoints • 4.5 km • Active Express Route',
      isActive: true,
      totalDistanceKm: 4.5,
      waypoints: {
        create: [
          { name: 'Perumbilavu South Junction', sequenceOrder: 1, latitude: 10.6960, longitude: 76.0900, isStart: true, isEnd: false },
          { name: 'Perumbilavu Market Gate', sequenceOrder: 2, latitude: 10.6980, longitude: 76.0915, isStart: false, isEnd: false },
          { name: 'Perumbilavu Office / Home (My Stop)', sequenceOrder: 3, latitude: 10.698731, longitude: 76.091942, isStart: false, isEnd: false },
          { name: 'Kottakkal Highway North Gate', sequenceOrder: 4, latitude: 10.7020, longitude: 76.0950, isStart: false, isEnd: true },
        ]
      }
    }
  });

  await prisma.sellingRoute.create({
    data: {
      vendorId: v2User.vendorProfile.id,
      name: 'Kunnamkulam - Perumbilavu Dairy Express',
      description: '3 Waypoints • 5.2 km • Active Milk Express',
      isActive: true,
      totalDistanceKm: 5.2,
      waypoints: {
        create: [
          { name: 'Kunnamkulam Dairy Hub', sequenceOrder: 1, latitude: 10.6510, longitude: 76.0710, isStart: true, isEnd: false },
          { name: 'Perumbilavu Royal College Gate', sequenceOrder: 2, latitude: 10.6950, longitude: 76.0900, isStart: false, isEnd: false },
          { name: 'Perumbilavu Center Gate', sequenceOrder: 3, latitude: 10.698731, longitude: 76.091942, isStart: false, isEnd: true },
        ]
      }
    }
  });

  await prisma.sellingRoute.create({
    data: {
      vendorId: v3User.vendorProfile.id,
      name: 'Pattambi - Perumbilavu Fruit Corridor',
      description: '3 Waypoints • 6.8 km • Active Fruit Route',
      isActive: true,
      totalDistanceKm: 6.8,
      waypoints: {
        create: [
          { name: 'Pattambi Highway Junction', sequenceOrder: 1, latitude: 10.7100, longitude: 76.1000, isStart: true, isEnd: false },
          { name: 'Perumbilavu Bypass Stop', sequenceOrder: 2, latitude: 10.7020, longitude: 76.0940, isStart: false, isEnd: false },
          { name: 'Perumbilavu Central Square', sequenceOrder: 3, latitude: 10.6987, longitude: 76.0919, isStart: false, isEnd: true },
        ]
      }
    }
  });

  await prisma.sellingRoute.create({
    data: {
      vendorId: v4User.vendorProfile.id,
      name: 'Chavakkad Coast - Perumbilavu Seafood Run',
      description: '3 Waypoints • 7.4 km • Active Seafood Route',
      isActive: true,
      totalDistanceKm: 7.4,
      waypoints: {
        create: [
          { name: 'Chavakkad Harbor', sequenceOrder: 1, latitude: 10.5360, longitude: 76.0250, isStart: true, isEnd: false },
          { name: 'Chowannur Gate', sequenceOrder: 2, latitude: 10.6800, longitude: 76.0850, isStart: false, isEnd: false },
          { name: 'Perumbilavu Fish Stand', sequenceOrder: 3, latitude: 10.6965, longitude: 76.0890, isStart: false, isEnd: true },
        ]
      }
    }
  });

  await prisma.sellingRoute.create({
    data: {
      vendorId: v5User.vendorProfile.id,
      name: 'Perumbilavu Evening Bakery Loop',
      description: '3 Waypoints • 2.8 km • Active Bakery Route',
      isActive: true,
      totalDistanceKm: 2.8,
      waypoints: {
        create: [
          { name: 'Perumbilavu Bakery Depot', sequenceOrder: 1, latitude: 10.6995, longitude: 76.0910, isStart: true, isEnd: false },
          { name: 'Perumbilavu School Gate', sequenceOrder: 2, latitude: 10.6980, longitude: 76.0915, isStart: false, isEnd: false },
          { name: 'Perumbilavu Office / Home (My Stop)', sequenceOrder: 3, latitude: 10.698731, longitude: 76.091942, isStart: false, isEnd: true },
        ]
      }
    }
  });

  console.log('✅ Selling Routes & Waypoints seeded for all 5 Perumbilavu vendors.');

  // ─── 6. SEED NOTIFICATIONS, BOOKING, FAVORITES, DAILY TRACKING ───
  await prisma.notification.createMany({
    data: [
      {
        buyerId: buyerProfileId,
        title: 'Perumbilavu Fresh Organic Veggies is Live!',
        body: 'Perumbilavu Fresh Organic Veggies (+91 9349523779) is broadcasting live near Perumbilavu Highway Junction!',
        type: 'VENDOR_LIVE',
        icon: 'notifications_active',
        isRead: false,
      },
      {
        buyerId: buyerProfileId,
        title: 'Order Arriving Soon',
        body: 'Booking ONW-77881 is 2 minutes away from Perumbilavu Junction.',
        type: 'ORDER_ARRIVING',
        icon: 'local_shipping',
        isRead: true,
      },
    ]
  });

  await prisma.booking.create({
    data: {
      bookingNumber: 'ONW-77881',
      buyerId: buyerProfileId,
      vendorId: v1User.vendorProfile.id,
      status: 'EN_ROUTE',
      totalAmount: 0.0,
      notifyOnReach: true,
      ringOnReach: true,
      dailyTracking: true,
      notes: 'Investor Demo Booking - Deliver to Perumbilavu Office',
      items: {
        create: [
          { productId: p1.id, productName: 'Organic Red Tomatoes', quantity: 2.0, unitPrice: 0.0, totalPrice: 0.0 },
          { productId: p2.id, productName: 'Nendran Bananas', quantity: 1.0, unitPrice: 0.0, totalPrice: 0.0 },
        ]
      }
    }
  });

  await prisma.buyerFavorite.create({
    data: {
      buyerId: buyerProfileId,
      vendorId: v1User.vendorProfile.id,
    }
  });

  await prisma.dailyTracking.create({
    data: {
      buyerId: buyerProfileId,
      vendorId: v1User.vendorProfile.id,
      notifyOnReach: true,
      ringOnReach: true,
      dailyTracking: true,
    }
  });

  console.log('🎉 Full Seeding for Perumbilavu, Thrissur completed successfully!');
}

main()
  .catch((e) => {
    console.error('❌ Seeding Error:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
