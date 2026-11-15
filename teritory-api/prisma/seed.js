const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  console.log('🌱 Starting Teritory Database Seed...');

  // 1. Clean existing records in reverse dependency order
  await prisma.waypointValidation.deleteMany({});
  await prisma.tripParticipant.deleteMany({});
  await prisma.trip.deleteMany({});
  await prisma.tripVote.deleteMany({});
  await prisma.savedTripPlan.deleteMany({});
  await prisma.tripWaypoint.deleteMany({});
  await prisma.tripPlan.deleteMany({});
  await prisma.rallyParticipant.deleteMany({});
  await prisma.legendaryRally.deleteMany({});
  await prisma.communityMessage.deleteMany({});
  await prisma.communityActivity.deleteMany({});
  await prisma.communityMember.deleteMany({});
  await prisma.community.deleteMany({});
  await prisma.clanMember.deleteMany({});
  await prisma.clan.deleteMany({});
  await prisma.flagReaction.deleteMany({});
  await prisma.flagComment.deleteMany({});
  await prisma.flag.deleteMany({});
  await prisma.passportStamp.deleteMany({});
  await prisma.friendRelationship.deleteMany({});
  await prisma.notification.deleteMany({});
  await prisma.serviceListing.deleteMany({});
  await prisma.serviceProvider.deleteMany({});
  await prisma.refreshToken.deleteMany({});
  await prisma.user.deleteMany({});

  console.log('🧹 Cleaned existing tables.');

  // 2. Seed Users
  const usersData = [
    {
      id: 'u1',
      displayName: 'Arjun Nair',
      handle: 'arjunnair',
      phone: '+919876543210',
      email: 'arjun@teritory.app',
      avatarUrl: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150',
      bio: 'Wanderer across the Western Ghats 🏔️ Exploring uncharted territories.',
      country: 'India',
      countryCode: 'IN',
      state: 'Kerala',
      district: 'Palakkad',
      totalFlags: 42,
      majorFlags: 14,
      countriesVisited: 4,
      continentsVisited: 2,
      totalTravelDays: 78,
      completedTripsCount: 6,
      legendaryRalliesCount: 3,
      mapStyle: 'midnight_oceanic',
      isTripMode: false,
    },
    {
      id: 'u2',
      displayName: 'Priya Menon',
      handle: 'priyamenon',
      phone: '+919876543211',
      email: 'priya@teritory.app',
      avatarUrl: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150',
      bio: 'Tea garden trails & foggy summits 🌿 Munnar native.',
      country: 'India',
      countryCode: 'IN',
      state: 'Kerala',
      district: 'Idukki',
      totalFlags: 38,
      majorFlags: 12,
      countriesVisited: 3,
      continentsVisited: 1,
      totalTravelDays: 62,
      completedTripsCount: 5,
      legendaryRalliesCount: 2,
    },
    {
      id: 'u3',
      displayName: 'Rahul Varma',
      handle: 'rahulvarma',
      phone: '+919876543212',
      email: 'rahul@teritory.app',
      avatarUrl: 'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?w=150',
      bio: 'Motorcycle expeditions & coastal sunrises 🏍️',
      country: 'India',
      countryCode: 'IN',
      state: 'Kerala',
      district: 'Ernakulam',
      totalFlags: 51,
      majorFlags: 19,
      countriesVisited: 6,
      continentsVisited: 2,
      totalTravelDays: 95,
      completedTripsCount: 8,
      legendaryRalliesCount: 4,
    },
    {
      id: 'u4',
      displayName: 'Ananya Iyer',
      handle: 'ananyaiyer',
      phone: '+919876543213',
      email: 'ananya@teritory.app',
      avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
      bio: 'Heritage archivist & backpacker 🏛️ Exploring Malabar temples.',
      country: 'India',
      countryCode: 'IN',
      state: 'Kerala',
      district: 'Kozhikode',
      totalFlags: 29,
      majorFlags: 9,
      countriesVisited: 2,
      continentsVisited: 1,
      totalTravelDays: 45,
      completedTripsCount: 3,
      legendaryRalliesCount: 1,
    },
    {
      id: 'u5',
      displayName: 'Vivek Krishnan',
      handle: 'vivekkrishnan',
      phone: '+919876543214',
      email: 'vivek@teritory.app',
      avatarUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
      bio: 'Off-road 4x4 trails & jungle survival camps 🏕️',
      country: 'India',
      countryCode: 'IN',
      state: 'Kerala',
      district: 'Wayanad',
      totalFlags: 63,
      majorFlags: 22,
      countriesVisited: 5,
      continentsVisited: 2,
      totalTravelDays: 110,
      completedTripsCount: 10,
      legendaryRalliesCount: 5,
    },
  ];

  for (const u of usersData) {
    await prisma.user.create({ data: u });
  }
  console.log(`👤 Seeded ${usersData.length} Users.`);

  // 3. Seed Passport Stamps
  await prisma.passportStamp.createMany({
    data: [
      { userId: 'u1', title: 'Western Ghats Pioneer', category: 'Exploration', date: 'Oct 2026', badgeColor: '#10B981', icon: 'landscape' },
      { userId: 'u1', title: 'Athirappilly Monsoon Conqueror', category: 'Waterfalls', date: 'Aug 2026', badgeColor: '#3B82F6', icon: 'water_drop' },
      { userId: 'u1', title: 'First 10 Flags Dropped', category: 'Milestones', date: 'Jun 2026', badgeColor: '#F59E0B', icon: 'flag' },
    ],
  });

  // 4. Seed Friend Relationships
  await prisma.friendRelationship.createMany({
    data: [
      { senderId: 'u1', receiverId: 'u2', status: 'ACCEPTED', category: 'TRAVEL_BUDDIES' },
      { senderId: 'u1', receiverId: 'u3', status: 'ACCEPTED', category: 'TRAVEL_BUDDIES' },
      { senderId: 'u1', receiverId: 'u5', status: 'ACCEPTED', category: 'FAVORITES' },
      { senderId: 'u4', receiverId: 'u1', status: 'PENDING' },
    ],
  });

  // 5. Seed Clans
  const c1 = await prisma.clan.create({
    data: {
      id: 'c1',
      name: 'Sahyadri Wanderers',
      description: 'Mountain trail enthusiasts traversing the peaks and mist of the Western Ghats.',
      coverImageUrl: 'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?w=600',
      region: 'Western Ghats',
      interestTag: 'Trekking & High Altitude',
      chieftainId: 'u1',
      memberCount: 142,
      communitiesCount: 2,
    },
  });

  const c2 = await prisma.clan.create({
    data: {
      id: 'c2',
      name: 'Malabar Riders',
      description: 'Motorcycle wanderers exploring historic spice routes and rainforest curves.',
      coverImageUrl: 'https://images.unsplash.com/photo-1558981403-c5f9899a28bc?w=600',
      region: 'Malabar Coast',
      interestTag: 'Motorcycle Expeditions',
      chieftainId: 'u3',
      memberCount: 98,
      communitiesCount: 1,
    },
  });

  await prisma.clanMember.createMany({
    data: [
      { clanId: 'c1', userId: 'u1', role: 'CHIEFTAIN' },
      { clanId: 'c1', userId: 'u2', role: 'MEMBER' },
      { clanId: 'c1', userId: 'u5', role: 'MODERATOR' },
      { clanId: 'c2', userId: 'u3', role: 'CHIEFTAIN' },
      { clanId: 'c2', userId: 'u1', role: 'MEMBER' },
    ],
  });

  // 6. Seed Communities
  const comm1 = await prisma.community.create({
    data: {
      id: 'comm1',
      name: 'Silent Valley Trekkers',
      description: 'Preserving and treading light in the deepest evergreen rainforests.',
      coverImageUrl: 'https://images.unsplash.com/photo-1448375240586-882707db888b?w=600',
      parentClanId: 'c1',
      interestTags: ['rainforest', 'endangered', 'silent-valley'],
      memberCount: 45,
      activeTripPlansCount: 2,
    },
  });

  const comm2 = await prisma.community.create({
    data: {
      id: 'comm2',
      name: 'Munnar High-Altitude Campers',
      description: 'Camp under the southern stars above 2000 meters.',
      coverImageUrl: 'https://images.unsplash.com/photo-1506744038136-46273834b3fb?w=600',
      parentClanId: 'c1',
      interestTags: ['camping', 'munnar', 'fog-trails'],
      memberCount: 68,
      activeTripPlansCount: 1,
    },
  });

  await prisma.communityMember.createMany({
    data: [
      { communityId: 'comm1', userId: 'u1', role: 'CREATOR' },
      { communityId: 'comm1', userId: 'u2', role: 'MEMBER' },
      { communityId: 'comm1', userId: 'u5', role: 'MODERATOR' },
      { communityId: 'comm2', userId: 'u2', role: 'CREATOR' },
      { communityId: 'comm2', userId: 'u1', role: 'MEMBER' },
    ],
  });

  // 7. Seed Community Messages & Feed Activities
  await prisma.communityMessage.createMany({
    data: [
      { communityId: 'comm1', userId: 'u1', text: 'Welcome everyone! Who is planning to visit Sairandhri watchtower next weekend?' },
      { communityId: 'comm1', userId: 'u5', text: 'I am in! Make sure to take the forest department transit permit early.' },
      { communityId: 'comm1', userId: 'u2', text: 'Weather is looking clear with light morning mist!' },
    ],
  });

  await prisma.communityActivity.createMany({
    data: [
      { communityId: 'comm1', userId: 'u1', type: 'ANNOUNCEMENT', title: 'Monsoon Trail Guidelines Updated', description: 'Leech guards and waterproof footwear recommended.' },
      { communityId: 'comm1', userId: 'u5', type: 'FLAG_DROP', title: 'New Flag Dropped: Kunthi River Bend', description: 'A hidden crystal clear river viewpoint.' },
    ],
  });

  // 8. Seed Flags (with Sub-Territories)
  const f1 = await prisma.flag.create({
    data: {
      id: 'f1',
      userId: 'u1',
      placeName: 'Athirappilly Falls',
      city: 'Thrissur',
      country: 'India',
      countryCode: 'IN',
      continent: 'Asia',
      latitude: 10.2850,
      longitude: 76.5698,
      isMajorFlag: true,
      category: 'Waterfall',
      notes: 'The Niagara of South India. Incredible thunderous spray during August!',
      photoUrl: 'https://images.unsplash.com/photo-1546708973-b339540b5162?w=600',
      kudos: 124,
    },
  });

  // Sub-territory (<5km from Athirappilly)
  const f2 = await prisma.flag.create({
    data: {
      id: 'f2',
      userId: 'u5',
      placeName: 'Charpa Forest Viewpoint',
      city: 'Thrissur',
      country: 'India',
      countryCode: 'IN',
      continent: 'Asia',
      latitude: 10.2980,
      longitude: 76.5910,
      isMajorFlag: false,
      category: 'Hidden Viewpoint',
      notes: 'Lesser known viewpoint 3km up the road from Athirappilly. Untouched and quiet!',
      photoUrl: 'https://images.unsplash.com/photo-1511497584788-87676104235f?w=600',
      kudos: 48,
    },
  });

  const f3 = await prisma.flag.create({
    data: {
      id: 'f3',
      userId: 'u2',
      placeName: 'Top Station Ridge',
      city: 'Munnar',
      country: 'India',
      countryCode: 'IN',
      continent: 'Asia',
      latitude: 10.1245,
      longitude: 77.2435,
      isMajorFlag: true,
      category: 'Scenic Ridge',
      notes: 'Panoramic sea of clouds overlooking the Tamil Nadu plains.',
      photoUrl: 'https://images.unsplash.com/photo-1506744038136-46273834b3fb?w=600',
      kudos: 95,
    },
  });

  await prisma.flagReaction.createMany({
    data: [
      { flagId: f1.id, userId: 'u1', type: 'EPIC' },
      { flagId: f1.id, userId: 'u2', type: 'GREAT_SHOT' },
      { flagId: f2.id, userId: 'u1', type: 'HIDDEN_GEM' },
      { flagId: f2.id, userId: 'u3', type: 'HIDDEN_GEM' },
    ],
  });

  await prisma.flagComment.createMany({
    data: [
      { flagId: f1.id, userId: 'u2', text: 'Magical rainbow visible here around 4 PM!' },
      { flagId: f2.id, userId: 'u1', text: 'True hidden gem! Only 5 minutes walk from the roadside curve.' },
    ],
  });

  // 9. Seed Trip Plans & Active Trips
  const tp1 = await prisma.tripPlan.create({
    data: {
      id: 'tp1',
      name: 'Palakkad to Kanyakumari Expedition',
      description: '5-day grand traverse from the Palakkad Gap to India southern-most tip.',
      createdById: 'u1',
      communityId: 'comm1',
      originName: 'Palakkad Fort',
      destinationName: 'Kanyakumari Pier',
      totalDistanceKm: 345.0,
      estimatedDays: 5,
      status: 'ACTIVE',
      voteCount: 18,
      waypoints: {
        create: [
          { orderIndex: 0, placeName: 'Palakkad Fort', latitude: 10.7764, longitude: 76.6548, category: 'Heritage', flagCount: 15 },
          { orderIndex: 1, placeName: 'Athirappilly Falls', latitude: 10.2850, longitude: 76.5698, category: 'Waterfall', flagCount: 42, distanceFromPrevKm: 85.0 },
          { orderIndex: 2, placeName: 'Vagamon Pine Forest', latitude: 9.6890, longitude: 76.9056, category: 'Scenic', flagCount: 28, distanceFromPrevKm: 98.0 },
          { orderIndex: 3, placeName: 'Jatayu Earth Center', latitude: 8.8655, longitude: 76.8683, category: 'Monument', flagCount: 35, distanceFromPrevKm: 92.0 },
          { orderIndex: 4, placeName: 'Kanyakumari Sunrise Point', latitude: 8.0883, longitude: 77.5385, category: 'Coastal Tip', flagCount: 60, distanceFromPrevKm: 70.0 },
        ],
      },
    },
  });

  // Active Trip instance
  const trip1 = await prisma.trip.create({
    data: {
      id: 'trip1',
      tripPlanId: tp1.id,
      createdById: 'u1',
      status: 'ACTIVE',
      expiresAt: new Date(Date.now() + 14 * 24 * 60 * 60 * 1000), // +14 days
      participants: {
        create: [
          { userId: 'u1', status: 'IN_PROGRESS', badge: 'NONE' },
          { userId: 'u2', status: 'IN_PROGRESS', badge: 'NONE' },
          { userId: 'u3', status: 'JOINED', badge: 'NONE' },
        ],
      },
    },
  });

  // 10. Seed Legendary Rally
  await prisma.legendaryRally.create({
    data: {
      id: 'r1',
      name: 'Sunset Flag at Varkala Cliff',
      description: 'Gather at North Cliff helipad point for a collective synchronized flag drop at golden hour.',
      createdById: 'u1',
      latitude: 8.7379,
      longitude: 76.7163,
      placeName: 'Varkala Cliff',
      status: 'GATHERING',
      minParticipants: 3,
      maxParticipants: 20,
      expiresAt: new Date(Date.now() + 2 * 24 * 60 * 60 * 1000),
      participants: {
        create: [
          { userId: 'u1', hasArrived: true, arrivedAt: new Date() },
          { userId: 'u3', hasArrived: false },
        ],
      },
    },
  });

  // 11. Seed Service Providers (Gear & Food)
  const sp1 = await prisma.serviceProvider.create({
    data: {
      id: 'sp1',
      name: 'Sahyadri Expedition Gear & Tents',
      description: 'Weatherproof high-altitude tents, sleeping bags, and trekking poles rental.',
      category: 'Camping Gear',
      rating: 4.8,
      latitude: 10.2820,
      longitude: 76.5650,
      contactPhone: '+919447123456',
      isVerified: true,
      listings: {
        create: [
          { name: '4-Person Waterproof Alpine Tent', description: 'Dual-layer with rainfly and ground tarp', priceRange: '₹500 / day', category: 'Tents' },
          { name: 'Sub-Zero Sleeping Bag (-5°C)', description: 'Thermal down fill with compression sack', priceRange: '₹300 / day', category: 'Bedding' },
          { name: 'Carbon Fiber Trekking Pole Pair', description: 'Ultralight anti-shock walking poles', priceRange: '₹150 / day', category: 'Gear' },
        ],
      },
    },
  });

  const sp2 = await prisma.serviceProvider.create({
    data: {
      id: 'sp2',
      name: 'Malabar Heritage Kitchen',
      description: 'Authentic local Kerala cuisine, claypot fish curry, and hot appam.',
      category: 'Local Food Spot',
      rating: 4.7,
      latitude: 10.2880,
      longitude: 76.5720,
      contactPhone: '+919447987654',
      isVerified: true,
      listings: {
        create: [
          { name: 'Travancore Fish Curry Meals', description: 'Served on banana leaf with fresh catch', priceRange: '₹180', category: 'Meals' },
          { name: 'Ela Ada & Hot Cardamom Tea', description: 'Steamed rice parcels with jaggery coconut', priceRange: '₹60', category: 'Snacks' },
        ],
      },
    },
  });

  console.log('✅ Teritory Database seeded successfully with full test suite!');
}

main()
  .catch((e) => {
    console.error('❌ Seed error:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });

