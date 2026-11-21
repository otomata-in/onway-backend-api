const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  console.log('🌱 Starting Teritory Database Seed for Kazhakkoottam & Kerala...');

  // 1. Clean existing records in reverse dependency order
  try {
    await prisma.$executeRawUnsafe('DELETE FROM saved_flags;');
  } catch (_) {}

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
  // u_akhil is the requested user profile (Akhil V A)
  // u1 is retained so smoke tests expecting arjunnair (+919876543210) also pass
  const usersData = [
    {
      id: 'u_akhil',
      displayName: 'Akhil V A',
      handle: 'akhilva',
      phone: '+918848793417',
      email: 'akhilva@teritory.app',
      avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200',
      bio: 'Exploring Kazhakkoottam & beyond 🚀 Technology, mountain roads & coastal trails.',
      country: 'India',
      countryCode: 'IN',
      state: 'Kerala',
      district: 'Thiruvananthapuram',
      lastLatitude: 8.5686,
      lastLongitude: 76.8731,
      totalFlags: 28,
      majorFlags: 9,
      countriesVisited: 3,
      continentsVisited: 2,
      totalTravelDays: 54,
      completedTripsCount: 4,
      legendaryRalliesCount: 2,
      mapStyle: 'midnight_oceanic',
      isTripMode: true,
      isVerified: true,
    },
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
      lastLatitude: 10.7764,
      lastLongitude: 76.6548,
      totalFlags: 42,
      majorFlags: 14,
      countriesVisited: 4,
      continentsVisited: 2,
      totalTravelDays: 78,
      completedTripsCount: 6,
      legendaryRalliesCount: 3,
      mapStyle: 'midnight_oceanic',
      isTripMode: false,
      isVerified: true,
    },
    {
      id: 'u2',
      displayName: 'Priya Menon',
      handle: 'priyamenon',
      phone: '+919876543211',
      email: 'priya@teritory.app',
      avatarUrl: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150',
      bio: 'Coastal sunrises & cliff sunsets 🌊 Varkala & Kovalam explorer.',
      country: 'India',
      countryCode: 'IN',
      state: 'Kerala',
      district: 'Thiruvananthapuram',
      lastLatitude: 8.7335,
      lastLongitude: 76.7085,
      totalFlags: 38,
      majorFlags: 12,
      countriesVisited: 3,
      continentsVisited: 1,
      totalTravelDays: 62,
      completedTripsCount: 5,
      legendaryRalliesCount: 2,
      isVerified: true,
    },
    {
      id: 'u3',
      displayName: 'Rahul Varma',
      handle: 'rahulvarma',
      phone: '+919876543212',
      email: 'rahul@teritory.app',
      avatarUrl: 'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?w=150',
      bio: 'Motorcycle expeditions & Arabian sea curves 🏍️',
      country: 'India',
      countryCode: 'IN',
      state: 'Kerala',
      district: 'Thiruvananthapuram',
      lastLatitude: 8.3988,
      lastLongitude: 76.9785,
      totalFlags: 51,
      majorFlags: 19,
      countriesVisited: 6,
      continentsVisited: 2,
      totalTravelDays: 95,
      completedTripsCount: 8,
      legendaryRalliesCount: 4,
      isVerified: true,
    },
    {
      id: 'u4',
      displayName: 'Sneha Pillai',
      handle: 'snehapillai',
      phone: '+919876543213',
      email: 'sneha@teritory.app',
      avatarUrl: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=150',
      bio: 'Kazhakkoottam Technopark techie by week, trail runner by weekend 🏃‍♀️',
      country: 'India',
      countryCode: 'IN',
      state: 'Kerala',
      district: 'Thiruvananthapuram',
      lastLatitude: 8.5566,
      lastLongitude: 76.8820,
      totalFlags: 29,
      majorFlags: 8,
      countriesVisited: 2,
      continentsVisited: 1,
      totalTravelDays: 41,
      completedTripsCount: 3,
      legendaryRalliesCount: 1,
      isVerified: true,
    },
    {
      id: 'u5',
      displayName: 'Vivek Krishnan',
      handle: 'vivekkrishnan',
      phone: '+919876543214',
      email: 'vivek@teritory.app',
      avatarUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
      bio: 'Ponmudi fog chaser & Agasthyarkoodam trek enthusiast 🧗‍♂️',
      country: 'India',
      countryCode: 'IN',
      state: 'Kerala',
      district: 'Thiruvananthapuram',
      lastLatitude: 8.7598,
      lastLongitude: 77.1165,
      totalFlags: 34,
      majorFlags: 11,
      countriesVisited: 3,
      continentsVisited: 1,
      totalTravelDays: 58,
      completedTripsCount: 4,
      legendaryRalliesCount: 3,
      isVerified: true,
    },
  ];

  for (const u of usersData) {
    await prisma.user.create({ data: u });
  }
  console.log(`👤 Created ${usersData.length} users (including Akhil V A at +918848793417).`);

  // 3. Passport Stamps
  await prisma.passportStamp.createMany({
    data: [
      { userId: 'u_akhil', title: 'Kazhakkoottam Tech Explorer', category: 'Milestones', date: 'Nov 2026', badgeColor: '#3B82F6', icon: 'explore' },
      { userId: 'u_akhil', title: 'Ponmudi Summit Conqueror', category: 'Highlands', date: 'Oct 2026', badgeColor: '#10B981', icon: 'landscape' },
      { userId: 'u_akhil', title: 'Padmanabhaswamy Heritage', category: 'Wonders', date: 'Sep 2026', badgeColor: '#F59E0B', icon: 'stars' },
      { userId: 'u_akhil', title: 'Varkala Cliff Sunset', category: 'Coastal', date: 'Aug 2026', badgeColor: '#EC4899', icon: 'beach_access' },
      { userId: 'u1', title: 'Western Ghats Pioneer', category: 'Exploration', date: 'Oct 2026', badgeColor: '#10B981', icon: 'landscape' },
      { userId: 'u1', title: 'Athirappilly Monsoon Conqueror', category: 'Waterfalls', date: 'Aug 2026', badgeColor: '#3B82F6', icon: 'water_drop' },
    ],
  });

  // 4. Friend Relationships
  await prisma.friendRelationship.createMany({
    data: [
      // Akhil's friendships
      { senderId: 'u_akhil', receiverId: 'u2', status: 'ACCEPTED', category: 'TRAVEL_BUDDIES' },
      { senderId: 'u_akhil', receiverId: 'u3', status: 'ACCEPTED', category: 'TRAVEL_BUDDIES' },
      { senderId: 'u_akhil', receiverId: 'u5', status: 'ACCEPTED', category: 'FAVORITES' },
      { senderId: 'u4', receiverId: 'u_akhil', status: 'PENDING', category: 'TRAVEL_BUDDIES' }, // Incoming request for Akhil
      { senderId: 'u_akhil', receiverId: 'u1', status: 'PENDING', category: 'TRAVEL_BUDDIES' }, // Outgoing request from Akhil
      // Existing test friendships for u1
      { senderId: 'u1', receiverId: 'u2', status: 'ACCEPTED', category: 'TRAVEL_BUDDIES' },
      { senderId: 'u1', receiverId: 'u3', status: 'ACCEPTED', category: 'TRAVEL_BUDDIES' },
      { senderId: 'u1', receiverId: 'u5', status: 'ACCEPTED', category: 'FAVORITES' },
      { senderId: 'u4', receiverId: 'u1', status: 'PENDING', category: 'TRAVEL_BUDDIES' },
    ],
  });

  // 5. Clans
  const c1 = await prisma.clan.create({
    data: {
      id: 'c1',
      name: 'Travancore Voyagers',
      description: 'Expedition clan rooted in Thiruvananthapuram, exploring coastal trails, heritage palaces and misty Ghat peaks.',
      coverImageUrl: 'https://images.unsplash.com/photo-1590050752117-238cb0fb12b1?w=800',
      region: 'Thiruvananthapuram',
      interestTag: 'Coastal & Heritage',
      chieftainId: 'u_akhil',
      memberCount: 156,
      communitiesCount: 2,
    },
  });

  const c2 = await prisma.clan.create({
    data: {
      id: 'c2',
      name: 'Technopark Trailblazers',
      description: 'Kazhakkoottam and Technopark techies escaping keyboards for asphalt curves and high-altitude summits.',
      coverImageUrl: 'https://images.unsplash.com/photo-1558981403-c5f9899a28bc?w=800',
      region: 'Kazhakkoottam',
      interestTag: 'Motorcycle & Weekend Escapes',
      chieftainId: 'u5',
      memberCount: 124,
      communitiesCount: 1,
    },
  });

  const c3 = await prisma.clan.create({
    data: {
      id: 'c3',
      name: 'Malabar Riders',
      description: 'Motorcycle wanderers exploring historic spice routes and rainforest curves.',
      coverImageUrl: 'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?w=800',
      region: 'Malabar Coast',
      interestTag: 'Motorcycle Expeditions',
      chieftainId: 'u3',
      memberCount: 98,
      communitiesCount: 1,
    },
  });

  await prisma.clanMember.createMany({
    data: [
      { clanId: 'c1', userId: 'u_akhil', role: 'CHIEFTAIN' },
      { clanId: 'c1', userId: 'u2', role: 'MODERATOR' },
      { clanId: 'c1', userId: 'u3', role: 'MEMBER' },
      { clanId: 'c1', userId: 'u4', role: 'MEMBER' },
      { clanId: 'c1', userId: 'u1', role: 'MEMBER' },
      { clanId: 'c2', userId: 'u5', role: 'CHIEFTAIN' },
      { clanId: 'c2', userId: 'u_akhil', role: 'MEMBER' },
      { clanId: 'c2', userId: 'u4', role: 'MODERATOR' },
      { clanId: 'c3', userId: 'u3', role: 'CHIEFTAIN' },
      { clanId: 'c3', userId: 'u1', role: 'MEMBER' },
    ],
  });

  // 6. Communities
  const comm1 = await prisma.community.create({
    data: {
      id: 'comm1',
      name: 'Kazhakkoottam Tech Riders',
      description: 'Weekend early morning rides from Kazhakkoottam bypass to Ponmudi hairpins, Varkala cliffs, and Kovalam beaches.',
      coverImageUrl: 'https://images.unsplash.com/photo-1568772585407-9361f9bf3a87?w=800',
      parentClanId: 'c2',
      interestTags: ['kazhakkoottam', 'technopark', 'weekend-rides', 'ponmudi'],
      memberCount: 88,
      activeTripPlansCount: 2,
    },
  });

  const comm2 = await prisma.community.create({
    data: {
      id: 'comm2',
      name: 'Trivandrum Coast & Cliff Pioneers',
      description: 'Exploring the pristine coastal shelf from Menamkulam and Veli to Kovalam and Poovar estuaries.',
      coverImageUrl: 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=800',
      parentClanId: 'c1',
      interestTags: ['coastal', 'trivandrum', 'varkala', 'kovalam'],
      memberCount: 65,
      activeTripPlansCount: 2,
    },
  });

  await prisma.communityMember.createMany({
    data: [
      { communityId: 'comm1', userId: 'u_akhil', role: 'CREATOR' },
      { communityId: 'comm1', userId: 'u4', role: 'MODERATOR' },
      { communityId: 'comm1', userId: 'u5', role: 'MEMBER' },
      { communityId: 'comm1', userId: 'u1', role: 'MEMBER' },
      { communityId: 'comm2', userId: 'u_akhil', role: 'CREATOR' },
      { communityId: 'comm2', userId: 'u2', role: 'MODERATOR' },
      { communityId: 'comm2', userId: 'u3', role: 'MEMBER' },
    ],
  });

  // 7. Community Messages & Feed Activities
  await prisma.communityMessage.createMany({
    data: [
      { communityId: 'comm1', userId: 'u_akhil', text: 'Hey crew! Who is joining the sunrise sprint from Kazhakkoottam to Ponmudi tomorrow?' },
      { communityId: 'comm1', userId: 'u5', text: 'Count me in! Ponmudi 22 hairpins are foggy and beautiful early in the morning.' },
      { communityId: 'comm1', userId: 'u4', text: 'Meeting at Kazhakkoottam Technopark Phase 3 gate at 5:30 AM!' },
      { communityId: 'comm1', userId: 'u3', text: 'Got my Royal Enfield fueled and ready to roll.' },
      { communityId: 'comm2', userId: 'u_akhil', text: 'Welcome to Trivandrum Coast & Cliff Pioneers! Drop your favorite secret beach spots.' },
      { communityId: 'comm2', userId: 'u2', text: 'Menamkulam cliff point during sunset is stunning and completely uncrowded.' },
    ],
  });

  await prisma.communityActivity.createMany({
    data: [
      { communityId: 'comm1', userId: 'u_akhil', type: 'ANNOUNCEMENT', title: 'Sunrise Sprint Details Posted', description: 'Kazhakkoottam -> Nedumangad -> Kallar -> Ponmudi Summit.' },
      { communityId: 'comm1', userId: 'u5', type: 'FLAG_DROP', title: 'New Flag Dropped: Ponmudi Hairpin 18 View', description: 'Spectacular misty valley view.' },
      { communityId: 'comm2', userId: 'u2', type: 'FLAG_DROP', title: 'New Flag Dropped: Menamkulam Sunset Grove', description: 'Peaceful coconut grove right above the surf.' },
    ],
  });

  // 8. Seed Flags (Kazhakkoottam center: 8.5686, 76.8731)
  const flagsData = [
    // --- Kazhakkoottam Local (< 5 km) ---
    {
      id: 'f_kazh1',
      userId: 'u_akhil',
      placeName: 'Technopark Amphitheatre & Lily Pond',
      city: 'Kazhakkoottam',
      country: 'India',
      countryCode: 'IN',
      continent: 'Asia',
      latitude: 8.5566,
      longitude: 76.8820,
      isMajorFlag: false,
      category: 'Cultural',
      notes: 'Lush greenery and calm reflection pool inside the heart of Technopark Phase 1.',
      photoUrl: 'https://images.unsplash.com/photo-1519389950473-47ba0277781c?w=600',
      kudos: 84,
    },
    {
      id: 'f_kazh2',
      userId: 'u_akhil',
      placeName: 'Menamkulam Sunset Beach & Coconut Grove',
      city: 'Kazhakkoottam',
      country: 'India',
      countryCode: 'IN',
      continent: 'Asia',
      latitude: 8.5620,
      longitude: 76.8480,
      isMajorFlag: false,
      category: 'Coastal',
      notes: 'Quiet coastal stretch just 2 km west of Kazhakkoottam junction. Best golden hour reflection.',
      photoUrl: 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=600',
      kudos: 92,
    },
    {
      id: 'f_kazh3',
      userId: 'u5',
      placeName: 'Thumba Rocket Launch Memorial & St. Roch Church',
      city: 'Kazhakkoottam',
      country: 'India',
      countryCode: 'IN',
      continent: 'Asia',
      latitude: 8.5410,
      longitude: 76.8520,
      isMajorFlag: false,
      category: 'Cultural',
      notes: 'Where India space journey began under Dr. Vikram Sarabhai and Dr. APJ Abdul Kalam in 1963.',
      photoUrl: 'https://images.unsplash.com/photo-1517976487502-5bfb40a3f8f7?w=600',
      kudos: 118,
    },
    {
      id: 'f_kazh4',
      userId: 'u_akhil',
      placeName: 'Kadinamkulam Kayal & Backwater Jetty',
      city: 'Kazhakkoottam',
      country: 'India',
      countryCode: 'IN',
      continent: 'Asia',
      latitude: 8.5895,
      longitude: 76.8405,
      isMajorFlag: false,
      category: 'Coastal',
      notes: 'Serene backwater lake connecting to the historic Vamanapuram river and Anjengo canal.',
      photoUrl: 'https://images.unsplash.com/photo-1544644181-1484b3fdfc62?w=600',
      kudos: 67,
    },
    {
      id: 'f_kazh5',
      userId: 'u3',
      placeName: 'Veli Lake Floating Bridge & Tourist Village',
      city: 'Thiruvananthapuram',
      country: 'India',
      countryCode: 'IN',
      continent: 'Asia',
      latitude: 8.5130,
      longitude: 76.8870,
      isMajorFlag: false,
      category: 'Coastal',
      notes: 'Scenic lagoon where the Veli lake meets the Arabian sea with a floating pedestrian bridge.',
      photoUrl: 'https://images.unsplash.com/photo-1506744038136-46273834b3fb?w=600',
      kudos: 76,
    },
    {
      id: 'f_kazh6',
      userId: 'u4',
      placeName: 'Aakkulam Lake Boating & Glass Bridge',
      city: 'Thiruvananthapuram',
      country: 'India',
      countryCode: 'IN',
      continent: 'Asia',
      latitude: 8.5200,
      longitude: 76.9080,
      isMajorFlag: false,
      category: 'Viewpoint',
      notes: 'Peaceful lakefront tourist park with water sports, musical fountain, and valley views.',
      photoUrl: 'https://images.unsplash.com/photo-1501785888041-af3ef285b470?w=600',
      kudos: 53,
    },

    // --- Trivandrum City & Major Wonders (5 - 30 km) ---
    {
      id: 'f_padm',
      userId: 'u_akhil',
      placeName: 'Sree Padmanabhaswamy Temple',
      city: 'Thiruvananthapuram',
      country: 'India',
      countryCode: 'IN',
      continent: 'Asia',
      latitude: 8.4828,
      longitude: 76.9436,
      isMajorFlag: true,
      category: 'Heritage',
      notes: 'World-renowned architectural masterpiece with its 16th century 7-tier gopuram and Padmatheertham pond.',
      photoUrl: 'https://images.unsplash.com/photo-1582510003544-4d00b7f74220?w=600',
      kudos: 340,
    },
    {
      id: 'f_kovalam',
      userId: 'u3',
      placeName: 'Kovalam Lighthouse Beach & Cliff Promenade',
      city: 'Kovalam',
      country: 'India',
      countryCode: 'IN',
      continent: 'Asia',
      latitude: 8.3988,
      longitude: 76.9785,
      isMajorFlag: true,
      category: 'Coastal',
      notes: 'Iconic striped 30-meter lighthouse overlooking crescent palm-fringed bays.',
      photoUrl: 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=600',
      kudos: 215,
    },
    {
      id: 'f_shangh',
      userId: 'u2',
      placeName: 'Shanghumukham Beach & Sagarakanyaka Mermaid',
      city: 'Thiruvananthapuram',
      country: 'India',
      countryCode: 'IN',
      continent: 'Asia',
      latitude: 8.4795,
      longitude: 76.9125,
      isMajorFlag: false,
      category: 'Coastal',
      notes: 'Expansive golden sunset beach featuring Kanayi Kunhiraman colossal 35-meter mermaid sculpture.',
      photoUrl: 'https://images.unsplash.com/photo-1518837695005-2083093ee35b?w=600',
      kudos: 142,
    },
    {
      id: 'f_vizh',
      userId: 'u5',
      placeName: 'Vizhinjam International Port & Cave Temple',
      city: 'Vizhinjam',
      country: 'India',
      countryCode: 'IN',
      continent: 'Asia',
      latitude: 8.3750,
      longitude: 76.9950,
      isMajorFlag: false,
      category: 'Viewpoint',
      notes: 'Deep water mega container port breakwater alongside 8th-century rock-cut Shiva shrine.',
      photoUrl: 'https://images.unsplash.com/photo-1473496169904-658ba7c44d8a?w=600',
      kudos: 88,
    },
    {
      id: 'f_poovar',
      userId: 'u2',
      placeName: 'Poovar Golden Sand Estuary',
      city: 'Poovar',
      country: 'India',
      countryCode: 'IN',
      continent: 'Asia',
      latitude: 8.3180,
      longitude: 77.0720,
      isMajorFlag: true,
      category: 'Coastal',
      notes: 'Rare natural confluence where the river Neyyar, backwaters, and sea separate a golden sand spit.',
      photoUrl: 'https://images.unsplash.com/photo-1544644181-1484b3fdfc62?w=600',
      kudos: 180,
    },

    // --- North Coast & Highlands (20 - 50 km) ---
    {
      id: 'f_varkala',
      userId: 'u_akhil',
      placeName: 'Varkala North Cliff & Papanasam Beach',
      city: 'Varkala',
      country: 'India',
      countryCode: 'IN',
      continent: 'Asia',
      latitude: 8.7335,
      longitude: 76.7085,
      isMajorFlag: true,
      category: 'Viewpoint',
      notes: 'Unique tertiary sedimentary red laterite cliffs towering right above the Arabian sea with natural mineral springs.',
      photoUrl: 'https://images.unsplash.com/photo-1590050752117-238cb0fb12b1?w=600',
      kudos: 295,
    },
    {
      id: 'f_ponmudi',
      userId: 'u_akhil',
      placeName: 'Ponmudi Golden Peak (Varayadumotta Summit)',
      city: 'Ponmudi',
      country: 'India',
      countryCode: 'IN',
      continent: 'Asia',
      latitude: 8.7598,
      longitude: 77.1165,
      isMajorFlag: true,
      category: 'Trek',
      notes: 'Rolling misty green grasslands, 22 hairpin bends, cool mountain breeze at 1,100 meters altitude.',
      photoUrl: 'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?w=600',
      kudos: 260,
    },
    {
      id: 'f_kallar',
      userId: 'u3',
      placeName: 'Kallar River & Meenmutty Waterfalls',
      city: 'Kallar',
      country: 'India',
      countryCode: 'IN',
      continent: 'Asia',
      latitude: 8.7180,
      longitude: 77.1280,
      isMajorFlag: false,
      category: 'Waterfall',
      notes: 'Pristine forest trek through rounded golden river pebbles to multi-tiered jungle waterfalls.',
      photoUrl: 'https://images.unsplash.com/photo-1546708973-b339540b5162?w=600',
      kudos: 135,
    },
    {
      id: 'f_jatayu',
      userId: 'u2',
      placeName: 'Jatayu Earth Center',
      city: 'Chadayamangalam',
      country: 'India',
      countryCode: 'IN',
      continent: 'Asia',
      latitude: 8.8680,
      longitude: 76.8660,
      isMajorFlag: true,
      category: 'Heritage',
      notes: 'The world largest functional bird sculpture perched atop a 1,000 ft rocky hill summit.',
      photoUrl: 'https://images.unsplash.com/photo-1579783902614-a3fb3927b675?w=600',
      kudos: 410,
    },
    {
      id: 'f_agasth',
      userId: 'u5',
      placeName: 'Agasthyarkoodam Biological Reserve',
      city: 'Bonacaud',
      country: 'India',
      countryCode: 'IN',
      continent: 'Asia',
      latitude: 8.6720,
      longitude: 77.1850,
      isMajorFlag: true,
      category: 'Trek',
      notes: 'Second highest peak in Kerala (1,868m), revered sacred peak rich with rare medicinal orchids.',
      photoUrl: 'https://images.unsplash.com/photo-1519681393784-d120267933ba?w=600',
      kudos: 195,
    },
    {
      id: 'f_anjengo',
      userId: 'u_akhil',
      placeName: 'Anjengo Fort & Lighthouse (Anchuthengu)',
      city: 'Anchuthengu',
      country: 'India',
      countryCode: 'IN',
      continent: 'Asia',
      latitude: 8.6815,
      longitude: 76.7550,
      isMajorFlag: false,
      category: 'Heritage',
      notes: 'Historic 1695 British East India Company coastal fortress surrounded by coconut plantations and backwaters.',
      photoUrl: 'https://images.unsplash.com/photo-1568605117036-5fe5e7bab0b7?w=600',
      kudos: 95,
    },
    {
      id: 'f_munroe',
      userId: 'u4',
      placeName: 'Munroe Island Backwater Canals',
      city: 'Kollam',
      country: 'India',
      countryCode: 'IN',
      continent: 'Asia',
      latitude: 8.9950,
      longitude: 76.6120,
      isMajorFlag: true,
      category: 'Coastal',
      notes: 'Canoe cruise through narrow mangrove canals at the confluence of Ashtamudi Lake and Kallada River.',
      photoUrl: 'https://images.unsplash.com/photo-1544644181-1484b3fdfc62?w=600',
      kudos: 175,
    },

    // --- Central Kerala Highlights ---
    {
      id: 'f_athi',
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
      notes: 'The majestic Niagara of South India cascading 80 feet down Chalakudy River.',
      photoUrl: 'https://images.unsplash.com/photo-1546708973-b339540b5162?w=600',
      kudos: 210,
    },
    {
      id: 'f_topstn',
      userId: 'u1',
      placeName: 'Top Station Ridge',
      city: 'Munnar',
      country: 'India',
      countryCode: 'IN',
      continent: 'Asia',
      latitude: 10.1245,
      longitude: 77.2435,
      isMajorFlag: true,
      category: 'Viewpoint',
      notes: 'Panoramic sea of clouds overlooking the Western Ghats and Tamil Nadu plains.',
      photoUrl: 'https://images.unsplash.com/photo-1506744038136-46273834b3fb?w=600',
      kudos: 185,
    },
    {
      id: 'f_kochi',
      userId: 'u1',
      placeName: 'Kochi Marine Drive Waterfront Promenade',
      city: 'Kochi',
      country: 'India',
      countryCode: 'IN',
      continent: 'Asia',
      latitude: 9.9790,
      longitude: 76.2760,
      isMajorFlag: false,
      category: 'Coastal',
      notes: 'Bustling harbor walkway overlooking Kochi backwaters and the Rainbow Bridge.',
      photoUrl: 'https://images.unsplash.com/photo-1518837695005-2083093ee35b?w=600',
      kudos: 130,
    },
  ];

  for (const f of flagsData) {
    await prisma.flag.create({ data: f });
  }
  console.log(`🚩 Created ${flagsData.length} flags (with dense coverage around Kazhakkoottam & Trivandrum).`);

  // Reactions & Comments
  await prisma.flagReaction.createMany({
    data: [
      { flagId: 'f_kazh1', userId: 'u_akhil', type: 'EPIC' },
      { flagId: 'f_kazh2', userId: 'u_akhil', type: 'HIDDEN_GEM' },
      { flagId: 'f_kazh2', userId: 'u2', type: 'HIDDEN_GEM' },
      { flagId: 'f_kazh3', userId: 'u_akhil', type: 'EPIC' },
      { flagId: 'f_padm', userId: 'u_akhil', type: 'EPIC' },
      { flagId: 'f_varkala', userId: 'u_akhil', type: 'GREAT_SHOT' },
      { flagId: 'f_ponmudi', userId: 'u_akhil', type: 'EPIC' },
      { flagId: 'f_ponmudi', userId: 'u5', type: 'HIDDEN_GEM' },
      { flagId: 'f_athi', userId: 'u1', type: 'EPIC' },
      { flagId: 'f_athi', userId: 'u2', type: 'GREAT_SHOT' },
    ],
  });

  await prisma.flagComment.createMany({
    data: [
      { flagId: 'f_kazh1', userId: 'u4', text: 'Great place to stroll after a long day coding at Technopark!' },
      { flagId: 'f_kazh2', userId: 'u_akhil', text: 'Come around 5:45 PM for the best sky colors.' },
      { flagId: 'f_ponmudi', userId: 'u5', text: 'Hairpins 15 to 22 were completely covered in fog this morning. Pure bliss!' },
      { flagId: 'f_padm', userId: 'u3', text: 'Breathtaking stone carving details on the corridor pillars.' },
    ],
  });

  // 9. Wishlist / Saved Flags for Akhil
  try {
    await prisma.$executeRawUnsafe(`
      INSERT INTO saved_flags (user_id, flag_id) VALUES
      ('u_akhil', 'f_padm'),
      ('u_akhil', 'f_ponmudi'),
      ('u_akhil', 'f_varkala'),
      ('u_akhil', 'f_kazh2')
      ON CONFLICT DO NOTHING;
    `);
    console.log('🔖 Populated Wishlist saved flags for Akhil.');
  } catch (err) {
    console.warn('Could not populate saved_flags table:', err.message);
  }

  // 10. Trip Plans & Active Expedition
  // Plan 1: Active Trip for Akhil (Kazhakkoottam to Ponmudi Highlands)
  const tp_active = await prisma.tripPlan.create({
    data: {
      id: 'tp_active',
      name: 'Kazhakkoottam to Ponmudi Highlands Expedition',
      description: 'Scenic climb starting from Technopark Kazhakkoottam through Nedumangad palace and Kallar jungle up to Ponmudi Golden Peak.',
      createdById: 'u_akhil',
      communityId: 'comm1',
      originName: 'Kazhakkoottam Technopark',
      destinationName: 'Ponmudi Golden Peak',
      totalDistanceKm: 58.0,
      estimatedDays: 1,
      status: 'ACTIVE',
      voteCount: 24,
      waypoints: {
        create: [
          { orderIndex: 0, placeName: 'Kazhakkoottam Technopark Junction', latitude: 8.5686, longitude: 76.8731, category: 'Start Point', flagCount: 22 },
          { orderIndex: 1, placeName: 'Nedumangad Koyikkal Palace', latitude: 8.6010, longitude: 77.0010, category: 'Heritage', flagCount: 14, distanceFromPrevKm: 18.0 },
          { orderIndex: 2, placeName: 'Kallar Meenmutty Waterfalls', latitude: 8.7180, longitude: 77.1280, category: 'Waterfall', flagCount: 35, distanceFromPrevKm: 22.0 },
          { orderIndex: 3, placeName: 'Ponmudi 22 Hairpins Viewpoint', latitude: 8.7450, longitude: 77.1120, category: 'Mountain View', flagCount: 19, distanceFromPrevKm: 12.0 },
          { orderIndex: 4, placeName: 'Ponmudi Golden Peak (Varayadumotta)', latitude: 8.7598, longitude: 77.1165, category: 'Summit', flagCount: 48, distanceFromPrevKm: 6.0 },
        ],
      },
    },
  });

  // Active Trip instance
  await prisma.trip.create({
    data: {
      id: 'trip_akhil_active',
      tripPlanId: tp_active.id,
      createdById: 'u_akhil',
      status: 'ACTIVE',
      expiresAt: new Date(Date.now() + 14 * 24 * 60 * 60 * 1000), // +14 days
      participants: {
        create: [
          { userId: 'u_akhil', status: 'IN_PROGRESS', badge: 'NONE' },
          { userId: 'u1', status: 'IN_PROGRESS', badge: 'NONE' },
          { userId: 'u5', status: 'IN_PROGRESS', badge: 'NONE' },
          { userId: 'u3', status: 'JOINED', badge: 'NONE' },
          { userId: 'u2', status: 'JOINED', badge: 'NONE' },
        ],
      },
    },
  });

  // Proposed Plan 2 (South Travancore Coastal Route)
  const tp2 = await prisma.tripPlan.create({
    data: {
      id: 'tp2',
      name: 'South Travancore Coastal Route',
      description: 'Cruising the Arabian coastline from Kazhakkoottam beaches down to Poovar mangrove estuary.',
      createdById: 'u3',
      communityId: 'comm2',
      originName: 'Kazhakkoottam Junction',
      destinationName: 'Poovar Golden Beach',
      totalDistanceKm: 42.0,
      estimatedDays: 1,
      status: 'PROPOSED',
      voteCount: 19,
      waypoints: {
        create: [
          { orderIndex: 0, placeName: 'Kazhakkoottam Menamkulam Beach', latitude: 8.5620, longitude: 76.8480, category: 'Coastal' },
          { orderIndex: 1, placeName: 'Veli Lake Floating Bridge', latitude: 8.5130, longitude: 76.8870, category: 'Coastal Lagoon', distanceFromPrevKm: 8.0 },
          { orderIndex: 2, placeName: 'Shanghumukham Beach', latitude: 8.4795, longitude: 76.9125, category: 'Beach', distanceFromPrevKm: 6.0 },
          { orderIndex: 3, placeName: 'Kovalam Lighthouse Beach', latitude: 8.3988, longitude: 76.9785, category: 'Lighthouse', distanceFromPrevKm: 14.0 },
          { orderIndex: 4, placeName: 'Poovar Golden Sand Estuary', latitude: 8.3180, longitude: 77.0720, category: 'Estuary', distanceFromPrevKm: 14.0 },
        ],
      },
    },
  });

  // Proposed Plan 3 (Cliffs, Backwaters & Jatayu Odyssey)
  const tp3 = await prisma.tripPlan.create({
    data: {
      id: 'tp3',
      name: 'Cliffs, Backwaters & Jatayu Odyssey',
      description: 'From Kazhakkoottam north along backwaters to the red Varkala cliffs and Jatayu mythical rock.',
      createdById: 'u2',
      communityId: 'comm1',
      originName: 'Kazhakkoottam Technopark',
      destinationName: 'Jatayu Earth Center',
      totalDistanceKm: 52.0,
      estimatedDays: 2,
      status: 'PROPOSED',
      voteCount: 15,
      waypoints: {
        create: [
          { orderIndex: 0, placeName: 'Kazhakkoottam Kadinamkulam Jetty', latitude: 8.5895, longitude: 76.8405, category: 'Backwater' },
          { orderIndex: 1, placeName: 'Anjengo Fort & Lighthouse', latitude: 8.6815, longitude: 76.7550, category: 'Historic Fort', distanceFromPrevKm: 15.0 },
          { orderIndex: 2, placeName: 'Varkala North Cliff', latitude: 8.7335, longitude: 76.7085, category: 'Cliff View', distanceFromPrevKm: 11.0 },
          { orderIndex: 3, placeName: 'Jatayu Earth Center', latitude: 8.8680, longitude: 76.8660, category: 'Monument', distanceFromPrevKm: 26.0 },
        ],
      },
    },
  });

  // Saved plan for Akhil
  await prisma.savedTripPlan.create({
    data: {
      userId: 'u_akhil',
      tripPlanId: tp3.id,
    },
  });

  console.log('🗺️ Seeded Active Trip, Proposed Plans & Saved Expeditions.');

  // 11. Legendary Rallies around Kazhakkoottam & Trivandrum
  await prisma.legendaryRally.create({
    data: {
      id: 'r_ponmudi',
      name: 'Kazhakkoottam to Ponmudi 22 Hairpins Sprint',
      description: 'Synchronized morning flag rally starting from Kazhakkoottam bypass up to the misty summit of Ponmudi.',
      createdById: 'u_akhil',
      latitude: 8.7598,
      longitude: 77.1165,
      placeName: 'Ponmudi Golden Peak',
      status: 'GATHERING',
      minParticipants: 3,
      maxParticipants: 25,
      expiresAt: new Date(Date.now() + 3 * 24 * 60 * 60 * 1000),
      participants: {
        create: [
          { userId: 'u_akhil', hasArrived: false },
          { userId: 'u5', hasArrived: true, arrivedAt: new Date() },
          { userId: 'u3', hasArrived: false },
          { userId: 'u4', hasArrived: false },
        ],
      },
    },
  });

  await prisma.legendaryRally.create({
    data: {
      id: 'r_varkala',
      name: 'Sunset Flag at Varkala North Cliff',
      description: 'Gather at North Cliff helipad point for a synchronized sunset flag staking at golden hour.',
      createdById: 'u2',
      latitude: 8.7335,
      longitude: 76.7085,
      placeName: 'Varkala Cliff Helipad',
      status: 'GATHERING',
      minParticipants: 3,
      maxParticipants: 20,
      expiresAt: new Date(Date.now() + 2 * 24 * 60 * 60 * 1000),
      participants: {
        create: [
          { userId: 'u2', hasArrived: true, arrivedAt: new Date() },
          { userId: 'u_akhil', hasArrived: false },
          { userId: 'u3', hasArrived: false },
        ],
      },
    },
  });

  // 12. Service Providers (Gear & Food around Kazhakkoottam & Trivandrum)
  // Food Spot 1: Right at Kazhakkoottam
  await prisma.serviceProvider.create({
    data: {
      id: 'sp_food1',
      name: 'The Yellow Chilli Kazhakkoottam',
      description: 'Celebrated North Indian specialties and regional Malabar coastal fusion right off the Technopark bypass.',
      category: 'Local Food Spot',
      rating: 4.8,
      latitude: 8.5670,
      longitude: 76.8745,
      contactPhone: '+919447101010',
      isVerified: true,
      listings: {
        create: [
          { name: 'Nadan Kozhi Curry & Malabar Parottas', description: 'Slow cooked country chicken with spices', priceRange: '₹280', category: 'Main Course' },
          { name: 'Travancore Prawn Ghee Roast', description: 'Fresh catch tossed in aromatic ghee and curry leaves', priceRange: '₹390', category: 'Seafood' },
          { name: 'Mango Kulfi & Tender Coconut Payasam', description: 'Chilled local desserts', priceRange: '₹140', category: 'Dessert' },
        ],
      },
    },
  });

  // Food Spot 2: Technopark Phase 3 Glasshouse
  await prisma.serviceProvider.create({
    data: {
      id: 'sp_food2',
      name: 'Open Glasshouse Cafe - Technopark',
      description: 'Artisan espresso, sourdough sandwiches, and fresh smoothies with lush garden views.',
      category: 'Local Food Spot',
      rating: 4.7,
      latitude: 8.5490,
      longitude: 76.8920,
      contactPhone: '+919447202020',
      isVerified: true,
      listings: {
        create: [
          { name: 'Kerala Spiced Cold Brew', description: 'Single origin roasted coffee infused with cardamom', priceRange: '₹160', category: 'Beverages' },
          { name: 'Avocado & Herb Toast', description: 'Fresh avocado mash on toasted seeded sourdough', priceRange: '₹220', category: 'Breakfast' },
        ],
      },
    },
  });

  // Food Spot 3: Zam Zam Kazhakkoottam
  await prisma.serviceProvider.create({
    data: {
      id: 'sp_food3',
      name: 'Zam Zam Authentic Arabian - Kazhakkoottam',
      description: 'Famous charcoal chicken grills, authentic Shawarmas, and traditional Yemeni Mandi.',
      category: 'Local Food Spot',
      rating: 4.6,
      latitude: 8.5695,
      longitude: 76.8720,
      contactPhone: '+919447303030',
      isVerified: true,
      listings: {
        create: [
          { name: 'Quarter Al Faham Chicken with Kuboos', description: 'Charcoal grilled tender spiced chicken', priceRange: '₹180', category: 'Grills' },
          { name: 'Chicken Shawarma Plate', description: 'Sliced marinated chicken with garlic toum and pickles', priceRange: '₹160', category: 'Arabian' },
        ],
      },
    },
  });

  // Gear Rental 1: Kazhakkoottam Adventure & Trek Rentals
  await prisma.serviceProvider.create({
    data: {
      id: 'sp_gear1',
      name: 'Kazhakkoottam Adventure & Trek Gear Hub',
      description: 'Complete high-altitude camping tents, sleeping bags, waterproof rucksacks and trekking poles.',
      category: 'Camping Gear',
      rating: 4.9,
      latitude: 8.5650,
      longitude: 76.8760,
      contactPhone: '+919447404040',
      isVerified: true,
      listings: {
        create: [
          { name: 'Quechua 3-Person Waterproof Tent', description: 'Wind resistant with ground tarp and pegs', priceRange: '₹400 / day', category: 'Tents' },
          { name: '0°C Thermal Sleeping Bag', description: 'Compact down filling for chilly Ponmudi nights', priceRange: '₹250 / day', category: 'Bedding' },
          { name: 'Anti-Shock Trekking Poles (Pair)', description: 'Telescopic aluminum alloy with cork grip', priceRange: '₹120 / day', category: 'Gear' },
          { name: '65L Waterproof Expedition Rucksack', description: 'Ergonomic lumbar support with rain cover', priceRange: '₹200 / day', category: 'Backpacks' },
        ],
      },
    },
  });

  // Gear Rental 2: Motorcycle Rentals
  await prisma.serviceProvider.create({
    data: {
      id: 'sp_gear2',
      name: 'Travancore Royal Moto Rentals - Kazhakkoottam',
      description: 'Touring motorcycles prepped for Ghat passes and coastal road trips (helmets & jackets included).',
      category: 'Camping Gear',
      rating: 4.8,
      latitude: 8.5680,
      longitude: 76.8710,
      contactPhone: '+919447505050',
      isVerified: true,
      listings: {
        create: [
          { name: 'Royal Enfield Himalayan 450', description: 'All-terrain tourer with dual panniers and mobile mount', priceRange: '₹1,400 / day', category: 'Motorcycles' },
          { name: 'Royal Enfield Hunter 350', description: 'Agile city and coastal cruiser', priceRange: '₹900 / day', category: 'Motorcycles' },
          { name: 'All-Weather Riding Jacket & Gloves', description: 'CE-certified level 2 armor protection', priceRange: '₹250 / day', category: 'Apparel' },
        ],
      },
    },
  });

  console.log('⛺ Seeded Gear Providers & Food spots in Kazhakkoottam.');

  // 13. Notifications for Akhil
  await prisma.notification.createMany({
    data: [
      {
        userId: 'u_akhil',
        type: 'SYSTEM',
        title: 'Welcome to Teritory, Akhil!',
        body: 'Your home base in Kazhakkoottam is ready. Explore nearby spots, active rallies, and expedition routes.',
        icon: 'explore',
        actionUrl: '/explore',
      },
      {
        userId: 'u_akhil',
        type: 'FRIEND_REQUEST',
        title: 'Sneha Pillai sent you a friend request',
        body: 'Sneha from Kazhakkoottam wants to connect with your exploration crew.',
        icon: 'person_add',
        actionUrl: '/profile/friends',
      },
      {
        userId: 'u_akhil',
        type: 'TRIP_STARTED',
        title: 'Expedition Ready: Ponmudi Highlands',
        body: 'Your expedition "Kazhakkoottam to Ponmudi Highlands" is live! 4 travelers have joined.',
        icon: 'trip',
        actionUrl: '/trips/trip_akhil_active/active',
      },
      {
        userId: 'u_akhil',
        type: 'RALLY_STARTED',
        title: 'Legendary Rally: Ponmudi 22 Hairpins',
        body: 'The rally "Kazhakkoottam to Ponmudi 22 Hairpins Sprint" is gathering participants.',
        icon: 'rally',
        actionUrl: '/explore',
      },
    ],
  });

  console.log('🔔 Created notifications for Akhil V A.');
  console.log('🎉 Database successfully seeded with rich Kazhakkoottam data!');
}

main()
  .catch((e) => {
    console.error('❌ Error during seeding:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
