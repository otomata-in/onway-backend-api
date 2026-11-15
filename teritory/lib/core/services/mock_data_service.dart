import '../models/user_models.dart';
import '../models/clan_models.dart';
import '../models/community_models.dart';
import '../models/trip_models.dart';
import '../models/rally_models.dart';
import '../models/service_models.dart';
import '../models/leaderboard_models.dart';
import '../models/notification_models.dart';

class MockDataService {
  static final MockDataService instance = MockDataService._internal();
  MockDataService._internal();

  // ─── Users ───────────────────────────────────────────────────────────
  List<User> get users => _users;
  User get currentUser => _users[0];

  static final List<User> _users = [
    User(
      id: 'u1',
      email: 'arjun.nair@teritory.app',
      phone: '+919846012345',
      displayName: 'Arjun Nair',
      handle: '@arjun_explorer',
      avatarUrl: 'https://picsum.photos/seed/arjun/200',
      bio: 'Western Ghats wanderer. Chasing waterfalls and sunrise trails.',
      createdAt: DateTime(2025, 3, 15),
      authProvider: 'google',
    ),
    User(
      id: 'u2',
      email: 'meera.krishnan@teritory.app',
      phone: '+919847023456',
      displayName: 'Meera Krishnan',
      handle: '@meera_trails',
      avatarUrl: 'https://picsum.photos/seed/meera/200',
      bio: 'Backpacker & mountain lover from Munnar.',
      createdAt: DateTime(2025, 4, 2),
      authProvider: 'email',
    ),
    User(
      id: 'u3',
      email: 'rahul.menon@teritory.app',
      phone: '+919848034567',
      displayName: 'Rahul Menon',
      handle: '@rahul_nomad',
      avatarUrl: 'https://picsum.photos/seed/rahul/200',
      bio: 'Photographer. Capturing Kerala one flag at a time.',
      createdAt: DateTime(2025, 4, 10),
      authProvider: 'google',
    ),
    User(
      id: 'u4',
      email: 'divya.pillai@teritory.app',
      phone: '+919849045678',
      displayName: 'Divya Pillai',
      handle: '@divya_wanders',
      avatarUrl: 'https://picsum.photos/seed/divya/200',
      bio: 'Solo traveler. Off-the-beaten-path enthusiast.',
      createdAt: DateTime(2025, 5, 1),
      authProvider: 'email',
    ),
    User(
      id: 'u5',
      email: 'kiran.das@teritory.app',
      phone: '+919850056789',
      displayName: 'Kiran Das',
      handle: '@kiran_trek',
      avatarUrl: 'https://picsum.photos/seed/kiran/200',
      bio: 'Trek leader & camping gear nerd from Wayanad.',
      createdAt: DateTime(2025, 5, 20),
      authProvider: 'google',
    ),
    User(
      id: 'u6',
      email: 'anjali.varma@teritory.app',
      phone: '+919851067890',
      displayName: 'Anjali Varma',
      handle: '@anjali_coast',
      avatarUrl: 'https://picsum.photos/seed/anjali/200',
      bio: 'Beach bum. Varkala cliff sunsets are my therapy.',
      createdAt: DateTime(2025, 6, 5),
      authProvider: 'email',
    ),
    User(
      id: 'u7',
      email: 'vishnu.kumar@teritory.app',
      phone: '+919852078901',
      displayName: 'Vishnu Kumar',
      handle: '@vishnu_peaks',
      avatarUrl: 'https://picsum.photos/seed/vishnu/200',
      bio: 'Himalayan trekker. Summited 12 peaks so far.',
      createdAt: DateTime(2025, 6, 15),
      authProvider: 'google',
    ),
    User(
      id: 'u8',
      email: 'priya.suresh@teritory.app',
      phone: '+919853089012',
      displayName: 'Priya Suresh',
      handle: '@priya_wild',
      avatarUrl: 'https://picsum.photos/seed/priya/200',
      bio: 'Wildlife photographer & nature guide in Thekkady.',
      createdAt: DateTime(2025, 7, 1),
      authProvider: 'email',
    ),
    User(
      id: 'u9',
      email: 'sanjay.thomas@teritory.app',
      phone: '+919854090123',
      displayName: 'Sanjay Thomas',
      handle: '@sanjay_ride',
      avatarUrl: 'https://picsum.photos/seed/sanjay/200',
      bio: 'Motorcycle nomad. Rode from Kochi to Ladakh twice.',
      createdAt: DateTime(2025, 7, 20),
      authProvider: 'google',
    ),
    User(
      id: 'u10',
      email: 'lakshmi.raj@teritory.app',
      phone: '+919855001234',
      displayName: 'Lakshmi Raj',
      handle: '@lakshmi_heritage',
      avatarUrl: 'https://picsum.photos/seed/lakshmi/200',
      bio: 'Heritage & temple explorer. History nerd at heart.',
      createdAt: DateTime(2025, 8, 1),
      authProvider: 'email',
    ),
  ];

  // ─── Friend Relationships ────────────────────────────────────────────
  List<FriendRelationship> get friendRelationships => _friendRelationships;

  static final List<FriendRelationship> _friendRelationships = [
    FriendRelationship(
      id: 'fr1',
      userId: 'u1',
      friendId: 'u2',
      status: FriendStatus.accepted,
      since: DateTime(2025, 4, 5),
      category: FriendCategory.travelBuddies,
    ),
    FriendRelationship(
      id: 'fr2',
      userId: 'u1',
      friendId: 'u3',
      status: FriendStatus.accepted,
      since: DateTime(2025, 4, 15),
      category: FriendCategory.favorites,
    ),
    FriendRelationship(
      id: 'fr3',
      userId: 'u1',
      friendId: 'u5',
      status: FriendStatus.accepted,
      since: DateTime(2025, 6, 1),
      category: FriendCategory.travelBuddies,
    ),
    FriendRelationship(
      id: 'fr4',
      userId: 'u1',
      friendId: 'u6',
      status: FriendStatus.accepted,
      since: DateTime(2025, 6, 10),
    ),
    FriendRelationship(
      id: 'fr5',
      userId: 'u1',
      friendId: 'u9',
      status: FriendStatus.pending,
      since: DateTime(2025, 8, 1),
    ),
    FriendRelationship(
      id: 'fr6',
      userId: 'u2',
      friendId: 'u4',
      status: FriendStatus.accepted,
      since: DateTime(2025, 5, 10),
      category: FriendCategory.family,
    ),
    FriendRelationship(
      id: 'fr7',
      userId: 'u3',
      friendId: 'u8',
      status: FriendStatus.accepted,
      since: DateTime(2025, 7, 5),
      category: FriendCategory.travelBuddies,
    ),
    FriendRelationship(
      id: 'fr8',
      userId: 'u10',
      friendId: 'u1',
      status: FriendStatus.pending,
      since: DateTime(2025, 8, 10),
    ),
  ];

  // ─── Clans ───────────────────────────────────────────────────────────
  List<Clan> get clans => _clans;

  static final List<Clan> _clans = [
    Clan(
      id: 'clan1',
      name: 'Kerala Explorers',
      description:
          'The largest clan of backpackers, trekkers, and flag hunters exploring every corner of God\'s Own Country. From misty Munnar peaks to tranquil Alleppey backwaters.',
      coverImageUrl: 'https://picsum.photos/seed/kerala_clan/800/400',
      region: 'Kerala',
      interestTag: 'backpacking',
      memberCount: 342,
      communitiesCount: 3,
      chieftainId: 'u1',
      chieftainName: 'Arjun Nair',
      isPublic: true,
      createdAt: DateTime(2025, 3, 20),
    ),
    Clan(
      id: 'clan2',
      name: 'Himalayan Trekkers',
      description:
          'Summit seekers and high-altitude explorers. We chase snow-capped peaks, alpine meadows, and the thrill of the climb across the mighty Himalayas.',
      coverImageUrl: 'https://picsum.photos/seed/himalaya_clan/800/400',
      region: 'Himachal Pradesh & Uttarakhand',
      interestTag: 'trekking',
      memberCount: 518,
      communitiesCount: 2,
      chieftainId: 'u7',
      chieftainName: 'Vishnu Kumar',
      isPublic: true,
      createdAt: DateTime(2025, 4, 1),
    ),
    Clan(
      id: 'clan3',
      name: 'Coastal Wanderers',
      description:
          'Sun, sand, and surf. Exploring India\'s stunning coastline from Varkala cliffs to Gokarna beaches, Kanyakumari sunrises to Andaman shores.',
      coverImageUrl: 'https://picsum.photos/seed/coastal_clan/800/400',
      region: 'Pan-India Coast',
      interestTag: 'beaches',
      memberCount: 275,
      communitiesCount: 2,
      chieftainId: 'u6',
      chieftainName: 'Anjali Varma',
      isPublic: true,
      createdAt: DateTime(2025, 5, 15),
    ),
  ];

  // ─── Communities ─────────────────────────────────────────────────────
  List<Community> get communities => _communities;

  static final List<Community> _communities = [
    Community(
      id: 'com1',
      name: 'Munnar Trail Blazers',
      description:
          'Trekking and camping routes around Munnar, Eravikulam, and Top Station. Share trails, drop flags, plan trips.',
      coverImageUrl: 'https://picsum.photos/seed/munnar_com/800/400',
      parentClanId: 'clan1',
      parentClanName: 'Kerala Explorers',
      memberCount: 128,
      activeTripPlansCount: 2,
      isPublic: true,
      interestTags: ['trekking', 'camping', 'tea_plantations'],
      createdAt: DateTime(2025, 4, 1),
    ),
    Community(
      id: 'com2',
      name: 'Wayanad Wilderness',
      description:
          'Deep forest trails, waterfalls, and wildlife spotting across Wayanad. From Edakkal caves to Banasura dam.',
      coverImageUrl: 'https://picsum.photos/seed/wayanad_com/800/400',
      parentClanId: 'clan1',
      parentClanName: 'Kerala Explorers',
      memberCount: 95,
      activeTripPlansCount: 1,
      isPublic: true,
      interestTags: ['wildlife', 'waterfalls', 'caves'],
      createdAt: DateTime(2025, 4, 15),
    ),
    Community(
      id: 'com3',
      name: 'Backwater Cruisers',
      description:
          'Houseboat routes, kayak trails, and hidden gems along Kerala\'s legendary backwaters from Alleppey to Kumarakom.',
      coverImageUrl: 'https://picsum.photos/seed/backwater_com/800/400',
      parentClanId: 'clan1',
      parentClanName: 'Kerala Explorers',
      memberCount: 76,
      activeTripPlansCount: 1,
      isPublic: true,
      interestTags: ['backwaters', 'houseboat', 'kayaking'],
      createdAt: DateTime(2025, 5, 1),
    ),
    Community(
      id: 'com4',
      name: 'Manali-Leh Riders',
      description:
          'Motorcycle and 4x4 road trip community for the legendary Manali-Leh highway and Ladakh adventures.',
      coverImageUrl: 'https://picsum.photos/seed/manali_leh/800/400',
      parentClanId: 'clan2',
      parentClanName: 'Himalayan Trekkers',
      memberCount: 210,
      activeTripPlansCount: 3,
      isPublic: true,
      interestTags: ['road_trip', 'motorcycle', 'high_altitude'],
      createdAt: DateTime(2025, 4, 20),
    ),
    Community(
      id: 'com5',
      name: 'Varkala-Kovalam Surf Club',
      description:
          'Surfers, cliff walkers, and sunset chasers along Kerala\'s most iconic beach stretches.',
      coverImageUrl: 'https://picsum.photos/seed/varkala_surf/800/400',
      parentClanId: 'clan3',
      parentClanName: 'Coastal Wanderers',
      memberCount: 63,
      activeTripPlansCount: 1,
      isPublic: true,
      interestTags: ['surfing', 'cliffs', 'beach_camping'],
      createdAt: DateTime(2025, 6, 1),
    ),
  ];

  // ─── Community Messages ──────────────────────────────────────────────
  List<CommunityMessage> get communityMessages => _communityMessages;

  static final List<CommunityMessage> _communityMessages = [
    CommunityMessage(
      id: 'msg1',
      communityId: 'com1',
      userId: 'u1',
      userName: 'Arjun Nair',
      userAvatar: 'https://picsum.photos/seed/arjun/200',
      text: 'Just flagged the Lockhart Gap viewpoint! The sunrise was absolutely insane today 🌄',
      createdAt: DateTime(2026, 11, 14, 6, 30),
    ),
    CommunityMessage(
      id: 'msg2',
      communityId: 'com1',
      userId: 'u2',
      userName: 'Meera Krishnan',
      userAvatar: 'https://picsum.photos/seed/meera/200',
      text: 'Anyone joining the Anamudi summit trip this weekend? We have 3 spots left.',
      createdAt: DateTime(2026, 11, 14, 8, 15),
    ),
    CommunityMessage(
      id: 'msg3',
      communityId: 'com1',
      userId: 'u5',
      userName: 'Kiran Das',
      userAvatar: 'https://picsum.photos/seed/kiran/200',
      text: 'I\'m in! Should we carry camping gear or are there shelters near the base?',
      createdAt: DateTime(2026, 11, 14, 8, 45),
    ),
    CommunityMessage(
      id: 'msg4',
      communityId: 'com1',
      userId: 'u2',
      userName: 'Meera Krishnan',
      userAvatar: 'https://picsum.photos/seed/meera/200',
      text: 'Carry your own tent. I\'ve added gear suggestions to the trip plan. Check it out!',
      createdAt: DateTime(2026, 11, 14, 9, 0),
    ),
    CommunityMessage(
      id: 'msg5',
      communityId: 'com2',
      userId: 'u3',
      userName: 'Rahul Menon',
      userAvatar: 'https://picsum.photos/seed/rahul/200',
      text: 'Chembra Peak trail is open again after the monsoon. Who wants to plan a group trek?',
      createdAt: DateTime(2026, 11, 13, 10, 0),
    ),
    CommunityMessage(
      id: 'msg6',
      communityId: 'com2',
      userId: 'u8',
      userName: 'Priya Suresh',
      userAvatar: 'https://picsum.photos/seed/priya/200',
      text: 'Spotted a herd of elephants near Muthanga last evening. Dropped a flag with photos 🐘',
      createdAt: DateTime(2026, 11, 13, 18, 30),
    ),
    CommunityMessage(
      id: 'msg7',
      communityId: 'com2',
      userId: 'u4',
      userName: 'Divya Pillai',
      userAvatar: 'https://picsum.photos/seed/divya/200',
      text: 'That\'s amazing Priya! How close were you? I\'m planning a wildlife photography trip there next month.',
      createdAt: DateTime(2026, 11, 13, 19, 15),
    ),
    CommunityMessage(
      id: 'msg8',
      communityId: 'com3',
      userId: 'u6',
      userName: 'Anjali Varma',
      userAvatar: 'https://picsum.photos/seed/anjali/200',
      text: 'The kayak route from Alleppey to Kumarakom is 22 km. Did it in 5 hours. Totally worth it!',
      createdAt: DateTime(2026, 11, 12, 16, 0),
    ),
    CommunityMessage(
      id: 'msg9',
      communityId: 'com3',
      userId: 'u1',
      userName: 'Arjun Nair',
      userAvatar: 'https://picsum.photos/seed/arjun/200',
      text: 'Anjali, did you rent the kayak locally or bring your own? Planning a similar trip.',
      createdAt: DateTime(2026, 11, 12, 17, 30),
    ),
    CommunityMessage(
      id: 'msg10',
      communityId: 'com3',
      userId: 'u6',
      userName: 'Anjali Varma',
      userAvatar: 'https://picsum.photos/seed/anjali/200',
      text: 'Rented from a local service. I\'ll share the contact in the services section.',
      createdAt: DateTime(2026, 11, 12, 17, 45),
    ),
    CommunityMessage(
      id: 'msg11',
      communityId: 'com4',
      userId: 'u9',
      userName: 'Sanjay Thomas',
      userAvatar: 'https://picsum.photos/seed/sanjay/200',
      text: 'Rohtang Pass is clear. Perfect window for the next 2 weeks. Let\'s rally!',
      createdAt: DateTime(2026, 11, 14, 7, 0),
    ),
    CommunityMessage(
      id: 'msg12',
      communityId: 'com4',
      userId: 'u7',
      userName: 'Vishnu Kumar',
      userAvatar: 'https://picsum.photos/seed/vishnu/200',
      text: 'I\'ll lead the convoy from Manali. Meeting point: Mall Road petrol pump at 5 AM.',
      createdAt: DateTime(2026, 11, 14, 9, 30),
    ),
    CommunityMessage(
      id: 'msg13',
      communityId: 'com5',
      userId: 'u6',
      userName: 'Anjali Varma',
      userAvatar: 'https://picsum.photos/seed/anjali/200',
      text: 'Surf conditions at Varkala are epic right now. 4-5 ft waves, offshore wind. 🏄‍♀️',
      createdAt: DateTime(2026, 11, 14, 11, 0),
    ),
    CommunityMessage(
      id: 'msg14',
      communityId: 'com5',
      userId: 'u4',
      userName: 'Divya Pillai',
      userAvatar: 'https://picsum.photos/seed/divya/200',
      text: 'Coming down from TVM this evening. Save me a board!',
      createdAt: DateTime(2026, 11, 14, 12, 0),
    ),
    CommunityMessage(
      id: 'msg15',
      communityId: 'com1',
      userId: 'u3',
      userName: 'Rahul Menon',
      userAvatar: 'https://picsum.photos/seed/rahul/200',
      text: 'New trail discovered between Top Station and Kodaikanal border. Dropped 4 flags along the route!',
      createdAt: DateTime(2026, 11, 14, 15, 0),
    ),
  ];

  // ─── Community Activities ────────────────────────────────────────────
  List<CommunityActivity> get communityActivities => _communityActivities;

  static final List<CommunityActivity> _communityActivities = [
    CommunityActivity(
      id: 'ca1',
      communityId: 'com1',
      type: CommunityActivityType.flagDrop,
      title: 'New flag at Lockhart Gap',
      description: 'Arjun Nair dropped a flag at the Lockhart Gap viewpoint with stunning sunrise photos.',
      userId: 'u1',
      userName: 'Arjun Nair',
      userAvatar: 'https://picsum.photos/seed/arjun/200',
      createdAt: DateTime(2026, 11, 14, 6, 35),
    ),
    CommunityActivity(
      id: 'ca2',
      communityId: 'com1',
      type: CommunityActivityType.tripComplete,
      title: 'Anamudi Base Camp trip completed',
      description: 'Meera Krishnan and 4 others completed the Anamudi Base Camp trek with full validation.',
      userId: 'u2',
      userName: 'Meera Krishnan',
      userAvatar: 'https://picsum.photos/seed/meera/200',
      createdAt: DateTime(2026, 11, 13, 18, 0),
    ),
    CommunityActivity(
      id: 'ca3',
      communityId: 'com2',
      type: CommunityActivityType.memberJoin,
      title: 'New member joined',
      description: 'Priya Suresh joined Wayanad Wilderness community.',
      userId: 'u8',
      userName: 'Priya Suresh',
      userAvatar: 'https://picsum.photos/seed/priya/200',
      createdAt: DateTime(2026, 11, 12, 10, 0),
    ),
    CommunityActivity(
      id: 'ca4',
      communityId: 'com2',
      type: CommunityActivityType.flagDrop,
      title: 'Wildlife flag near Muthanga',
      description: 'Priya Suresh flagged an elephant sighting near Muthanga Wildlife Sanctuary.',
      userId: 'u8',
      userName: 'Priya Suresh',
      userAvatar: 'https://picsum.photos/seed/priya/200',
      createdAt: DateTime(2026, 11, 13, 18, 35),
    ),
    CommunityActivity(
      id: 'ca5',
      communityId: 'com3',
      type: CommunityActivityType.announcement,
      title: 'Monsoon kayak routes updated',
      description: 'Post-monsoon kayak routes have been updated with new water-level data for Alleppey backwaters.',
      userId: 'u6',
      userName: 'Anjali Varma',
      userAvatar: 'https://picsum.photos/seed/anjali/200',
      createdAt: DateTime(2026, 11, 11, 14, 0),
    ),
    CommunityActivity(
      id: 'ca6',
      communityId: 'com3',
      type: CommunityActivityType.tripComplete,
      title: 'Alleppey-Kumarakom kayak trip done',
      description: 'Anjali Varma completed the 22 km kayak route from Alleppey to Kumarakom in 5 hours.',
      userId: 'u6',
      userName: 'Anjali Varma',
      userAvatar: 'https://picsum.photos/seed/anjali/200',
      createdAt: DateTime(2026, 11, 12, 16, 10),
    ),
    CommunityActivity(
      id: 'ca7',
      communityId: 'com4',
      type: CommunityActivityType.announcement,
      title: 'Rohtang Pass cleared',
      description: 'Rohtang Pass road is clear for the next 2 weeks. Plan your Manali-Leh trip now!',
      userId: 'u9',
      userName: 'Sanjay Thomas',
      userAvatar: 'https://picsum.photos/seed/sanjay/200',
      createdAt: DateTime(2026, 11, 14, 7, 5),
    ),
    CommunityActivity(
      id: 'ca8',
      communityId: 'com5',
      type: CommunityActivityType.flagDrop,
      title: 'Surf spot flagged at Varkala North',
      description: 'Anjali Varma flagged a new surf spot at Varkala North with 4-5 ft wave conditions.',
      userId: 'u6',
      userName: 'Anjali Varma',
      userAvatar: 'https://picsum.photos/seed/anjali/200',
      createdAt: DateTime(2026, 11, 14, 11, 5),
    ),
    CommunityActivity(
      id: 'ca9',
      communityId: 'com1',
      type: CommunityActivityType.memberJoin,
      title: 'New member joined',
      description: 'Lakshmi Raj joined Munnar Trail Blazers community.',
      userId: 'u10',
      userName: 'Lakshmi Raj',
      userAvatar: 'https://picsum.photos/seed/lakshmi/200',
      createdAt: DateTime(2026, 11, 10, 9, 0),
    ),
    CommunityActivity(
      id: 'ca10',
      communityId: 'com1',
      type: CommunityActivityType.flagDrop,
      title: 'New trail discovery',
      description: 'Rahul Menon discovered a trail between Top Station and Kodaikanal border with 4 flags.',
      userId: 'u3',
      userName: 'Rahul Menon',
      userAvatar: 'https://picsum.photos/seed/rahul/200',
      createdAt: DateTime(2026, 11, 14, 15, 5),
    ),
  ];

  // ─── Trip Plans ──────────────────────────────────────────────────────
  List<TripPlan> get tripPlans => _tripPlans;

  static final List<TripPlan> _tripPlans = [
    TripPlan(
      id: 'tp1',
      name: 'Munnar to Kodaikanal Ridge Run',
      description:
          'A 3-day trek connecting Munnar\'s tea estates to Kodaikanal\'s misty hills via hidden forest trails and waterfalls.',
      createdBy: 'u1',
      createdByName: 'Arjun Nair',
      communityId: 'com1',
      communityName: 'Munnar Trail Blazers',
      originName: 'Munnar Town',
      originLat: 10.0889,
      originLng: 77.0595,
      destinationName: 'Kodaikanal',
      destLat: 10.2381,
      destLng: 77.4892,
      estimatedDurationHours: 72,
      estimatedDistanceKm: 145,
      status: TripPlanStatus.voted,
      voteScore: 14,
      waypoints: [
        TripWaypoint(
          id: 'wp1_1',
          tripPlanId: 'tp1',
          orderIndex: 0,
          placeName: 'Lockhart Gap',
          latitude: 10.0712,
          longitude: 77.0523,
          category: 'viewpoint',
          flagCount: 8,
          distanceFromPrevKm: 0,
        ),
        TripWaypoint(
          id: 'wp1_2',
          tripPlanId: 'tp1',
          orderIndex: 1,
          placeName: 'Top Station',
          latitude: 10.1262,
          longitude: 77.2354,
          category: 'viewpoint',
          flagCount: 12,
          distanceFromPrevKm: 22,
        ),
        TripWaypoint(
          id: 'wp1_3',
          tripPlanId: 'tp1',
          orderIndex: 2,
          placeName: 'Chinnar Wildlife Sanctuary',
          latitude: 10.3000,
          longitude: 77.1833,
          category: 'wildlife',
          flagCount: 5,
          distanceFromPrevKm: 35,
        ),
        TripWaypoint(
          id: 'wp1_4',
          tripPlanId: 'tp1',
          orderIndex: 3,
          placeName: 'Marayoor Sandalwood Forest',
          latitude: 10.2762,
          longitude: 77.1625,
          category: 'forest',
          flagCount: 3,
          distanceFromPrevKm: 18,
        ),
        TripWaypoint(
          id: 'wp1_5',
          tripPlanId: 'tp1',
          orderIndex: 4,
          placeName: 'Berijam Lake',
          latitude: 10.2167,
          longitude: 77.4333,
          category: 'lake',
          flagCount: 6,
          distanceFromPrevKm: 40,
        ),
        TripWaypoint(
          id: 'wp1_6',
          tripPlanId: 'tp1',
          orderIndex: 5,
          placeName: 'Kodaikanal Lake',
          latitude: 10.2327,
          longitude: 77.4895,
          category: 'destination',
          flagCount: 15,
          distanceFromPrevKm: 30,
        ),
      ],
      gearSuggestions: [
        'Trekking boots',
        'Rain poncho',
        '2-person tent',
        'Sleeping bag (0°C rated)',
        'Headlamp',
        'Water purification tablets',
      ],
      createdAt: DateTime(2026, 10, 20),
    ),
    TripPlan(
      id: 'tp2',
      name: 'Wayanad Waterfall Circuit',
      description:
          'A 2-day loop covering the best waterfalls of Wayanad — from Meenmutty to Soochipara, with wildlife detours.',
      createdBy: 'u5',
      createdByName: 'Kiran Das',
      communityId: 'com2',
      communityName: 'Wayanad Wilderness',
      originName: 'Kalpetta',
      originLat: 11.6094,
      originLng: 76.0824,
      destinationName: 'Kalpetta',
      destLat: 11.6094,
      destLng: 76.0824,
      estimatedDurationHours: 48,
      estimatedDistanceKm: 85,
      status: TripPlanStatus.active,
      voteScore: 9,
      waypoints: [
        TripWaypoint(
          id: 'wp2_1',
          tripPlanId: 'tp2',
          orderIndex: 0,
          placeName: 'Edakkal Caves',
          latitude: 11.6308,
          longitude: 76.0297,
          category: 'heritage',
          flagCount: 10,
          distanceFromPrevKm: 0,
        ),
        TripWaypoint(
          id: 'wp2_2',
          tripPlanId: 'tp2',
          orderIndex: 1,
          placeName: 'Meenmutty Falls',
          latitude: 11.6833,
          longitude: 76.0167,
          category: 'waterfall',
          flagCount: 7,
          distanceFromPrevKm: 12,
        ),
        TripWaypoint(
          id: 'wp2_3',
          tripPlanId: 'tp2',
          orderIndex: 2,
          placeName: 'Banasura Sagar Dam',
          latitude: 11.6725,
          longitude: 75.9575,
          category: 'dam',
          flagCount: 6,
          distanceFromPrevKm: 15,
        ),
        TripWaypoint(
          id: 'wp2_4',
          tripPlanId: 'tp2',
          orderIndex: 3,
          placeName: 'Soochipara Falls',
          latitude: 11.6119,
          longitude: 76.1153,
          category: 'waterfall',
          flagCount: 9,
          distanceFromPrevKm: 28,
        ),
      ],
      gearSuggestions: [
        'Waterproof backpack cover',
        'Quick-dry clothing',
        'Trekking poles',
        'First aid kit',
      ],
      createdAt: DateTime(2026, 11, 1),
    ),
    TripPlan(
      id: 'tp3',
      name: 'Alleppey to Kanyakumari Coastal Drive',
      description:
          'A scenic 4-day road trip along Kerala\'s coast — houseboats, cliff walks, fishing villages, and the southernmost tip of India.',
      createdBy: 'u6',
      createdByName: 'Anjali Varma',
      communityId: 'com3',
      communityName: 'Backwater Cruisers',
      originName: 'Alleppey',
      originLat: 9.4981,
      originLng: 76.3388,
      destinationName: 'Kanyakumari',
      destLat: 8.0883,
      destLng: 77.5385,
      estimatedDurationHours: 96,
      estimatedDistanceKm: 270,
      status: TripPlanStatus.proposed,
      voteScore: 6,
      waypoints: [
        TripWaypoint(
          id: 'wp3_1',
          tripPlanId: 'tp3',
          orderIndex: 0,
          placeName: 'Marari Beach',
          latitude: 9.5911,
          longitude: 76.2889,
          category: 'beach',
          flagCount: 4,
          distanceFromPrevKm: 0,
        ),
        TripWaypoint(
          id: 'wp3_2',
          tripPlanId: 'tp3',
          orderIndex: 1,
          placeName: 'Kollam Beach',
          latitude: 8.8932,
          longitude: 76.6141,
          category: 'beach',
          flagCount: 3,
          distanceFromPrevKm: 80,
        ),
        TripWaypoint(
          id: 'wp3_3',
          tripPlanId: 'tp3',
          orderIndex: 2,
          placeName: 'Varkala Cliff',
          latitude: 8.7379,
          longitude: 76.7163,
          category: 'cliff',
          flagCount: 11,
          distanceFromPrevKm: 25,
        ),
        TripWaypoint(
          id: 'wp3_4',
          tripPlanId: 'tp3',
          orderIndex: 3,
          placeName: 'Kovalam Lighthouse Beach',
          latitude: 8.3988,
          longitude: 76.9785,
          category: 'beach',
          flagCount: 8,
          distanceFromPrevKm: 50,
        ),
        TripWaypoint(
          id: 'wp3_5',
          tripPlanId: 'tp3',
          orderIndex: 4,
          placeName: 'Padmanabhapuram Palace',
          latitude: 8.2462,
          longitude: 77.3262,
          category: 'heritage',
          flagCount: 5,
          distanceFromPrevKm: 55,
        ),
        TripWaypoint(
          id: 'wp3_6',
          tripPlanId: 'tp3',
          orderIndex: 5,
          placeName: 'Kanyakumari Temple',
          latitude: 8.0785,
          longitude: 77.5518,
          category: 'destination',
          flagCount: 18,
          distanceFromPrevKm: 60,
        ),
      ],
      gearSuggestions: [
        'Sunscreen SPF50',
        'Snorkeling mask',
        'Car phone mount',
        'Portable cooler',
        'Beach umbrella',
      ],
      createdAt: DateTime(2026, 11, 5),
    ),
  ];

  // ─── Active Trips ────────────────────────────────────────────────────
  List<Trip> get activeTrips => _activeTrips;

  static final List<Trip> _activeTrips = [
    Trip(
      id: 'trip1',
      tripPlanId: 'tp2',
      tripName: 'Wayanad Waterfall Circuit',
      organizerId: 'u5',
      status: TripStatus.active,
      startedAt: DateTime(2026, 11, 14, 6, 0),
      participants: [
        TripParticipant(
          id: 'part1_1',
          tripId: 'trip1',
          userId: 'u5',
          userName: 'Kiran Das',
          userAvatar: 'https://picsum.photos/seed/kiran/200',
          status: ParticipantStatus.inProgress,
          currentLat: 11.6308,
          currentLng: 76.0297,
          lastUpdated: DateTime(2026, 11, 14, 14, 30),
        ),
        TripParticipant(
          id: 'part1_2',
          tripId: 'trip1',
          userId: 'u3',
          userName: 'Rahul Menon',
          userAvatar: 'https://picsum.photos/seed/rahul/200',
          status: ParticipantStatus.inProgress,
          currentLat: 11.6350,
          currentLng: 76.0310,
          lastUpdated: DateTime(2026, 11, 14, 14, 25),
        ),
        TripParticipant(
          id: 'part1_3',
          tripId: 'trip1',
          userId: 'u8',
          userName: 'Priya Suresh',
          userAvatar: 'https://picsum.photos/seed/priya/200',
          status: ParticipantStatus.joined,
          currentLat: 11.6094,
          currentLng: 76.0824,
          lastUpdated: DateTime(2026, 11, 14, 7, 0),
        ),
      ],
    ),
    Trip(
      id: 'trip2',
      tripPlanId: 'tp1',
      tripName: 'Munnar to Kodaikanal Ridge Run',
      organizerId: 'u1',
      status: TripStatus.active,
      startedAt: DateTime(2026, 11, 12, 5, 0),
      participants: [
        TripParticipant(
          id: 'part2_1',
          tripId: 'trip2',
          userId: 'u1',
          userName: 'Arjun Nair',
          userAvatar: 'https://picsum.photos/seed/arjun/200',
          status: ParticipantStatus.inProgress,
          currentLat: 10.2762,
          currentLng: 77.1625,
          lastUpdated: DateTime(2026, 11, 14, 16, 0),
        ),
        TripParticipant(
          id: 'part2_2',
          tripId: 'trip2',
          userId: 'u2',
          userName: 'Meera Krishnan',
          userAvatar: 'https://picsum.photos/seed/meera/200',
          status: ParticipantStatus.inProgress,
          currentLat: 10.2800,
          currentLng: 77.1650,
          lastUpdated: DateTime(2026, 11, 14, 15, 45),
        ),
      ],
    ),
  ];

  // ─── Completed Trips (history) ───────────────────────────────────────
  List<TripCompletion> get tripCompletions => _tripCompletions;

  static final List<TripCompletion> _tripCompletions = [
    TripCompletion(
      id: 'tc1',
      tripId: 'trip_past_1',
      userId: 'u1',
      userName: 'Arjun Nair',
      completedAt: DateTime(2026, 9, 15),
      totalDistanceKm: 92,
      totalDurationHours: 36,
      waypointsValidated: 5,
      totalWaypoints: 5,
      badge: TripBadge.full,
      routeThumbnailUrl: 'https://picsum.photos/seed/trip_past_1/400/200',
    ),
    TripCompletion(
      id: 'tc2',
      tripId: 'trip_past_2',
      userId: 'u1',
      userName: 'Arjun Nair',
      completedAt: DateTime(2026, 8, 20),
      totalDistanceKm: 45,
      totalDurationHours: 12,
      waypointsValidated: 3,
      totalWaypoints: 4,
      badge: TripBadge.partial,
      routeThumbnailUrl: 'https://picsum.photos/seed/trip_past_2/400/200',
    ),
  ];

  // ─── Legendary Rallies ───────────────────────────────────────────────
  List<LegendaryRally> get rallies => _rallies;

  static final List<LegendaryRally> _rallies = [
    LegendaryRally(
      id: 'rally1',
      name: 'Munnar Sunrise Rally',
      organizerId: 'u1',
      organizerName: 'Arjun Nair',
      locationName: 'Top Station, Munnar',
      latitude: 10.1262,
      longitude: 77.2354,
      radiusMeters: 500,
      inviteType: RallyInviteType.community,
      communityId: 'com1',
      windowStartTime: DateTime(2026, 11, 16, 5, 0),
      windowEndTime: DateTime(2026, 11, 16, 7, 30),
      status: RallyStatus.pending,
      participantCount: 8,
      createdAt: DateTime(2026, 11, 10),
    ),
  ];

  List<RallyParticipant> get rallyParticipants => _rallyParticipants;

  static final List<RallyParticipant> _rallyParticipants = [
    RallyParticipant(
      id: 'rp1',
      rallyId: 'rally1',
      userId: 'u1',
      userName: 'Arjun Nair',
      userAvatar: 'https://picsum.photos/seed/arjun/200',
      joinedAt: DateTime(2026, 11, 10, 12, 0),
      isWithinRadius: false,
      latitude: 10.0889,
      longitude: 77.0595,
    ),
    RallyParticipant(
      id: 'rp2',
      rallyId: 'rally1',
      userId: 'u2',
      userName: 'Meera Krishnan',
      userAvatar: 'https://picsum.photos/seed/meera/200',
      joinedAt: DateTime(2026, 11, 10, 14, 0),
      isWithinRadius: false,
      latitude: 10.0900,
      longitude: 77.0610,
    ),
    RallyParticipant(
      id: 'rp3',
      rallyId: 'rally1',
      userId: 'u5',
      userName: 'Kiran Das',
      userAvatar: 'https://picsum.photos/seed/kiran/200',
      joinedAt: DateTime(2026, 11, 11, 8, 0),
      isWithinRadius: false,
      latitude: 11.6094,
      longitude: 76.0824,
    ),
  ];

  // ─── Service Listings ────────────────────────────────────────────────
  List<ServiceListing> get serviceListings => _serviceListings;

  static final List<ServiceListing> _serviceListings = [
    ServiceListing(
      id: 'svc1',
      providerId: 'sp1',
      providerName: 'Munnar Adventure Outfitters',
      serviceType: 'gear_rental',
      terrainType: 'mountain',
      title: 'Trekking Gear Package',
      description: 'Complete trekking kit: boots, poles, headlamp, rain poncho, and 45L backpack. Daily rental.',
      priceRange: '₹500-₹800/day',
      rating: 4.7,
      ratingCount: 142,
      latitude: 10.0889,
      longitude: 77.0595,
      distanceFromTerritoryKm: 0.5,
      imageUrls: [
        'https://picsum.photos/seed/gear1/400/300',
        'https://picsum.photos/seed/gear1b/400/300',
      ],
      bookingDeepLink: 'https://teritory.app/service/svc1',
    ),
    ServiceListing(
      id: 'svc2',
      providerId: 'sp1',
      providerName: 'Munnar Adventure Outfitters',
      serviceType: 'camping_equipment',
      terrainType: 'mountain',
      title: 'Camping Setup Kit',
      description: '2-person tent, sleeping bag, camping stove, and cookware set. Perfect for overnight treks.',
      priceRange: '₹700-₹1200/day',
      rating: 4.5,
      ratingCount: 98,
      latitude: 10.0889,
      longitude: 77.0595,
      distanceFromTerritoryKm: 0.5,
      imageUrls: [
        'https://picsum.photos/seed/camp1/400/300',
        'https://picsum.photos/seed/camp1b/400/300',
      ],
      bookingDeepLink: 'https://teritory.app/service/svc2',
    ),
    ServiceListing(
      id: 'svc3',
      providerId: 'sp2',
      providerName: 'Wayanad Trails & Guides',
      serviceType: 'guided_trek',
      terrainType: 'forest',
      title: 'Chembra Peak Guided Trek',
      description: 'Full-day guided trek to Chembra Peak\'s heart-shaped lake. Includes packed lunch and forest permits.',
      priceRange: '₹1500-₹2000/person',
      rating: 4.8,
      ratingCount: 215,
      latitude: 11.6094,
      longitude: 76.0824,
      distanceFromTerritoryKm: 8,
      imageUrls: [
        'https://picsum.photos/seed/chembra/400/300',
        'https://picsum.photos/seed/chembra2/400/300',
      ],
      bookingDeepLink: 'https://teritory.app/service/svc3',
    ),
    ServiceListing(
      id: 'svc4',
      providerId: 'sp3',
      providerName: 'Alleppey Backwater Adventures',
      serviceType: 'kayak_rental',
      terrainType: 'water',
      title: 'Kayak Day Rental',
      description: 'Single or tandem kayak with paddle, life jacket, and waterproof phone pouch. Route maps included.',
      priceRange: '₹600-₹1000/day',
      rating: 4.6,
      ratingCount: 87,
      latitude: 9.4981,
      longitude: 76.3388,
      distanceFromTerritoryKm: 2,
      imageUrls: [
        'https://picsum.photos/seed/kayak1/400/300',
      ],
      bookingDeepLink: 'https://teritory.app/service/svc4',
    ),
    ServiceListing(
      id: 'svc5',
      providerId: 'sp4',
      providerName: 'Varkala Surf School',
      serviceType: 'surf_lesson',
      terrainType: 'coastal',
      title: 'Beginner Surf Lesson',
      description: '2-hour surf lesson with board and wetsuit. All levels welcome. Certified instructors.',
      priceRange: '₹1200-₹1800/session',
      rating: 4.9,
      ratingCount: 176,
      latitude: 8.7379,
      longitude: 76.7163,
      distanceFromTerritoryKm: 1,
      imageUrls: [
        'https://picsum.photos/seed/surf1/400/300',
        'https://picsum.photos/seed/surf2/400/300',
      ],
      bookingDeepLink: 'https://teritory.app/service/svc5',
    ),
    ServiceListing(
      id: 'svc6',
      providerId: 'sp5',
      providerName: 'Thekkady Periyar Safaris',
      serviceType: 'wildlife_safari',
      terrainType: 'forest',
      title: 'Periyar Bamboo Rafting',
      description: 'Half-day bamboo rafting safari on Periyar Lake with wildlife guide. Elephant and bison sighting chances.',
      priceRange: '₹2500-₹3500/person',
      rating: 4.7,
      ratingCount: 310,
      latitude: 9.4667,
      longitude: 77.1667,
      distanceFromTerritoryKm: 15,
      imageUrls: [
        'https://picsum.photos/seed/periyar1/400/300',
      ],
      bookingDeepLink: 'https://teritory.app/service/svc6',
    ),
    ServiceListing(
      id: 'svc7',
      providerId: 'sp6',
      providerName: 'Gavi Eco Camp',
      serviceType: 'eco_stay',
      terrainType: 'forest',
      title: 'Gavi Forest Eco Tent',
      description: 'Eco tent accommodation inside Gavi forest with guided night walk and campfire dinner.',
      priceRange: '₹3000-₹4500/night',
      rating: 4.4,
      ratingCount: 65,
      latitude: 9.4000,
      longitude: 77.1333,
      distanceFromTerritoryKm: 20,
      imageUrls: [
        'https://picsum.photos/seed/gavi1/400/300',
        'https://picsum.photos/seed/gavi2/400/300',
      ],
      bookingDeepLink: 'https://teritory.app/service/svc7',
    ),
    ServiceListing(
      id: 'svc8',
      providerId: 'sp7',
      providerName: 'Kochi Bike Rentals',
      serviceType: 'vehicle_rental',
      terrainType: 'road',
      title: 'Royal Enfield Himalayan Rental',
      description: 'Royal Enfield Himalayan 450 with helmet, saddlebags, and roadside assistance. Min 3-day rental.',
      priceRange: '₹1200-₹1800/day',
      rating: 4.6,
      ratingCount: 234,
      latitude: 9.9312,
      longitude: 76.2673,
      distanceFromTerritoryKm: 45,
      imageUrls: [
        'https://picsum.photos/seed/bike1/400/300',
      ],
      bookingDeepLink: 'https://teritory.app/service/svc8',
    ),
    ServiceListing(
      id: 'svc9',
      providerId: 'sp2',
      providerName: 'Wayanad Trails & Guides',
      serviceType: 'camping_equipment',
      terrainType: 'forest',
      title: 'Hammock & Tarp Set',
      description: 'Lightweight hammock with mosquito net and rain tarp. Perfect for jungle overnight stays.',
      priceRange: '₹300-₹500/day',
      rating: 4.3,
      ratingCount: 56,
      latitude: 11.6094,
      longitude: 76.0824,
      distanceFromTerritoryKm: 8,
      imageUrls: [
        'https://picsum.photos/seed/hammock/400/300',
      ],
      bookingDeepLink: 'https://teritory.app/service/svc9',
    ),
    ServiceListing(
      id: 'svc10',
      providerId: 'sp8',
      providerName: 'Kanyakumari Heritage Tours',
      serviceType: 'guided_tour',
      terrainType: 'coastal',
      title: 'Sunrise Heritage Walk',
      description: 'Early morning guided walk covering Vivekananda Rock Memorial, Thiruvalluvar Statue, and Kanyakumari Temple.',
      priceRange: '₹800-₹1200/person',
      rating: 4.5,
      ratingCount: 128,
      latitude: 8.0785,
      longitude: 77.5518,
      distanceFromTerritoryKm: 0.3,
      imageUrls: [
        'https://picsum.photos/seed/kanyakumari1/400/300',
        'https://picsum.photos/seed/kanyakumari2/400/300',
      ],
      bookingDeepLink: 'https://teritory.app/service/svc10',
    ),
  ];

  // ─── Leaderboard Entries ─────────────────────────────────────────────
  List<LeaderboardEntry> get leaderboardEntries => _leaderboardEntries;

  static final List<LeaderboardEntry> _leaderboardEntries = [
    LeaderboardEntry(
      id: 'lb1', userId: 'u1', userName: 'Arjun Nair', userHandle: '@arjun_explorer',
      userAvatar: 'https://picsum.photos/seed/arjun/200',
      scope: LeaderboardScope.global, period: LeaderboardPeriod.alltime,
      rank: 1, compositeScore: 9850, totalFlags: 247, majorFlags: 18,
      countriesVisited: 5, continentsExplored: 2, completedTrips: 12,
      legendaryRallies: 3, communityContributions: 45, streakDays: 32,
    ),
    LeaderboardEntry(
      id: 'lb2', userId: 'u7', userName: 'Vishnu Kumar', userHandle: '@vishnu_peaks',
      userAvatar: 'https://picsum.photos/seed/vishnu/200',
      scope: LeaderboardScope.global, period: LeaderboardPeriod.alltime,
      rank: 2, compositeScore: 9200, totalFlags: 198, majorFlags: 22,
      countriesVisited: 8, continentsExplored: 3, completedTrips: 15,
      legendaryRallies: 5, communityContributions: 30, streakDays: 45,
    ),
    LeaderboardEntry(
      id: 'lb3', userId: 'u9', userName: 'Sanjay Thomas', userHandle: '@sanjay_ride',
      userAvatar: 'https://picsum.photos/seed/sanjay/200',
      scope: LeaderboardScope.global, period: LeaderboardPeriod.alltime,
      rank: 3, compositeScore: 8750, totalFlags: 312, majorFlags: 15,
      countriesVisited: 4, continentsExplored: 2, completedTrips: 9,
      legendaryRallies: 2, communityContributions: 28, streakDays: 18,
    ),
    LeaderboardEntry(
      id: 'lb4', userId: 'u2', userName: 'Meera Krishnan', userHandle: '@meera_trails',
      userAvatar: 'https://picsum.photos/seed/meera/200',
      scope: LeaderboardScope.global, period: LeaderboardPeriod.alltime,
      rank: 4, compositeScore: 7600, totalFlags: 175, majorFlags: 12,
      countriesVisited: 3, continentsExplored: 1, completedTrips: 10,
      legendaryRallies: 2, communityContributions: 38, streakDays: 25,
    ),
    LeaderboardEntry(
      id: 'lb5', userId: 'u5', userName: 'Kiran Das', userHandle: '@kiran_trek',
      userAvatar: 'https://picsum.photos/seed/kiran/200',
      scope: LeaderboardScope.global, period: LeaderboardPeriod.alltime,
      rank: 5, compositeScore: 7100, totalFlags: 156, majorFlags: 10,
      countriesVisited: 2, continentsExplored: 1, completedTrips: 14,
      legendaryRallies: 4, communityContributions: 52, streakDays: 40,
    ),
    LeaderboardEntry(
      id: 'lb6', userId: 'u6', userName: 'Anjali Varma', userHandle: '@anjali_coast',
      userAvatar: 'https://picsum.photos/seed/anjali/200',
      scope: LeaderboardScope.global, period: LeaderboardPeriod.alltime,
      rank: 6, compositeScore: 6800, totalFlags: 134, majorFlags: 9,
      countriesVisited: 4, continentsExplored: 2, completedTrips: 8,
      legendaryRallies: 1, communityContributions: 33, streakDays: 15,
    ),
    LeaderboardEntry(
      id: 'lb7', userId: 'u3', userName: 'Rahul Menon', userHandle: '@rahul_nomad',
      userAvatar: 'https://picsum.photos/seed/rahul/200',
      scope: LeaderboardScope.global, period: LeaderboardPeriod.alltime,
      rank: 7, compositeScore: 6500, totalFlags: 189, majorFlags: 8,
      countriesVisited: 3, continentsExplored: 1, completedTrips: 7,
      legendaryRallies: 1, communityContributions: 22, streakDays: 12,
    ),
    LeaderboardEntry(
      id: 'lb8', userId: 'u8', userName: 'Priya Suresh', userHandle: '@priya_wild',
      userAvatar: 'https://picsum.photos/seed/priya/200',
      scope: LeaderboardScope.global, period: LeaderboardPeriod.alltime,
      rank: 8, compositeScore: 5900, totalFlags: 145, majorFlags: 7,
      countriesVisited: 2, continentsExplored: 1, completedTrips: 6,
      legendaryRallies: 1, communityContributions: 40, streakDays: 28,
    ),
    LeaderboardEntry(
      id: 'lb9', userId: 'u4', userName: 'Divya Pillai', userHandle: '@divya_wanders',
      userAvatar: 'https://picsum.photos/seed/divya/200',
      scope: LeaderboardScope.global, period: LeaderboardPeriod.alltime,
      rank: 9, compositeScore: 5400, totalFlags: 112, majorFlags: 6,
      countriesVisited: 6, continentsExplored: 3, completedTrips: 5,
      legendaryRallies: 0, communityContributions: 18, streakDays: 8,
    ),
    LeaderboardEntry(
      id: 'lb10', userId: 'u10', userName: 'Lakshmi Raj', userHandle: '@lakshmi_heritage',
      userAvatar: 'https://picsum.photos/seed/lakshmi/200',
      scope: LeaderboardScope.global, period: LeaderboardPeriod.alltime,
      rank: 10, compositeScore: 4800, totalFlags: 98, majorFlags: 11,
      countriesVisited: 3, continentsExplored: 1, completedTrips: 4,
      legendaryRallies: 0, communityContributions: 15, streakDays: 5,
    ),
    // Monthly leaderboard subset
    LeaderboardEntry(
      id: 'lb11', userId: 'u5', userName: 'Kiran Das', userHandle: '@kiran_trek',
      userAvatar: 'https://picsum.photos/seed/kiran/200',
      scope: LeaderboardScope.global, period: LeaderboardPeriod.month,
      rank: 1, compositeScore: 1450, totalFlags: 28, majorFlags: 2,
      countriesVisited: 1, continentsExplored: 1, completedTrips: 3,
      legendaryRallies: 1, communityContributions: 12, streakDays: 30,
    ),
    LeaderboardEntry(
      id: 'lb12', userId: 'u1', userName: 'Arjun Nair', userHandle: '@arjun_explorer',
      userAvatar: 'https://picsum.photos/seed/arjun/200',
      scope: LeaderboardScope.global, period: LeaderboardPeriod.month,
      rank: 2, compositeScore: 1380, totalFlags: 32, majorFlags: 3,
      countriesVisited: 1, continentsExplored: 1, completedTrips: 2,
      legendaryRallies: 0, communityContributions: 8, streakDays: 28,
    ),
    LeaderboardEntry(
      id: 'lb13', userId: 'u3', userName: 'Rahul Menon', userHandle: '@rahul_nomad',
      userAvatar: 'https://picsum.photos/seed/rahul/200',
      scope: LeaderboardScope.global, period: LeaderboardPeriod.month,
      rank: 3, compositeScore: 1200, totalFlags: 25, majorFlags: 1,
      countriesVisited: 1, continentsExplored: 1, completedTrips: 2,
      legendaryRallies: 0, communityContributions: 6, streakDays: 12,
    ),
    // Weekly leaderboard subset
    LeaderboardEntry(
      id: 'lb14', userId: 'u6', userName: 'Anjali Varma', userHandle: '@anjali_coast',
      userAvatar: 'https://picsum.photos/seed/anjali/200',
      scope: LeaderboardScope.global, period: LeaderboardPeriod.week,
      rank: 1, compositeScore: 520, totalFlags: 12, majorFlags: 1,
      countriesVisited: 1, continentsExplored: 1, completedTrips: 1,
      legendaryRallies: 0, communityContributions: 5, streakDays: 7,
    ),
    LeaderboardEntry(
      id: 'lb15', userId: 'u1', userName: 'Arjun Nair', userHandle: '@arjun_explorer',
      userAvatar: 'https://picsum.photos/seed/arjun/200',
      scope: LeaderboardScope.global, period: LeaderboardPeriod.week,
      rank: 2, compositeScore: 480, totalFlags: 10, majorFlags: 1,
      countriesVisited: 1, continentsExplored: 1, completedTrips: 1,
      legendaryRallies: 0, communityContributions: 3, streakDays: 7,
    ),
    // Friends scope
    LeaderboardEntry(
      id: 'lb16', userId: 'u1', userName: 'Arjun Nair', userHandle: '@arjun_explorer',
      userAvatar: 'https://picsum.photos/seed/arjun/200',
      scope: LeaderboardScope.friends, period: LeaderboardPeriod.alltime,
      rank: 1, compositeScore: 9850, totalFlags: 247, majorFlags: 18,
      countriesVisited: 5, continentsExplored: 2, completedTrips: 12,
      legendaryRallies: 3, communityContributions: 45, streakDays: 32,
    ),
    LeaderboardEntry(
      id: 'lb17', userId: 'u2', userName: 'Meera Krishnan', userHandle: '@meera_trails',
      userAvatar: 'https://picsum.photos/seed/meera/200',
      scope: LeaderboardScope.friends, period: LeaderboardPeriod.alltime,
      rank: 2, compositeScore: 7600, totalFlags: 175, majorFlags: 12,
      countriesVisited: 3, continentsExplored: 1, completedTrips: 10,
      legendaryRallies: 2, communityContributions: 38, streakDays: 25,
    ),
    LeaderboardEntry(
      id: 'lb18', userId: 'u3', userName: 'Rahul Menon', userHandle: '@rahul_nomad',
      userAvatar: 'https://picsum.photos/seed/rahul/200',
      scope: LeaderboardScope.friends, period: LeaderboardPeriod.alltime,
      rank: 3, compositeScore: 6500, totalFlags: 189, majorFlags: 8,
      countriesVisited: 3, continentsExplored: 1, completedTrips: 7,
      legendaryRallies: 1, communityContributions: 22, streakDays: 12,
    ),
    LeaderboardEntry(
      id: 'lb19', userId: 'u5', userName: 'Kiran Das', userHandle: '@kiran_trek',
      userAvatar: 'https://picsum.photos/seed/kiran/200',
      scope: LeaderboardScope.friends, period: LeaderboardPeriod.alltime,
      rank: 4, compositeScore: 7100, totalFlags: 156, majorFlags: 10,
      countriesVisited: 2, continentsExplored: 1, completedTrips: 14,
      legendaryRallies: 4, communityContributions: 52, streakDays: 40,
    ),
    LeaderboardEntry(
      id: 'lb20', userId: 'u6', userName: 'Anjali Varma', userHandle: '@anjali_coast',
      userAvatar: 'https://picsum.photos/seed/anjali/200',
      scope: LeaderboardScope.friends, period: LeaderboardPeriod.alltime,
      rank: 5, compositeScore: 6800, totalFlags: 134, majorFlags: 9,
      countriesVisited: 4, continentsExplored: 2, completedTrips: 8,
      legendaryRallies: 1, communityContributions: 33, streakDays: 15,
    ),
    // Clan scope
    LeaderboardEntry(
      id: 'lb21', userId: 'u1', userName: 'Arjun Nair', userHandle: '@arjun_explorer',
      userAvatar: 'https://picsum.photos/seed/arjun/200',
      scope: LeaderboardScope.clan, period: LeaderboardPeriod.alltime,
      rank: 1, compositeScore: 9850, totalFlags: 247, majorFlags: 18,
      countriesVisited: 5, continentsExplored: 2, completedTrips: 12,
      legendaryRallies: 3, communityContributions: 45, streakDays: 32,
    ),
    LeaderboardEntry(
      id: 'lb22', userId: 'u2', userName: 'Meera Krishnan', userHandle: '@meera_trails',
      userAvatar: 'https://picsum.photos/seed/meera/200',
      scope: LeaderboardScope.clan, period: LeaderboardPeriod.alltime,
      rank: 2, compositeScore: 7600, totalFlags: 175, majorFlags: 12,
      countriesVisited: 3, continentsExplored: 1, completedTrips: 10,
      legendaryRallies: 2, communityContributions: 38, streakDays: 25,
    ),
    LeaderboardEntry(
      id: 'lb23', userId: 'u5', userName: 'Kiran Das', userHandle: '@kiran_trek',
      userAvatar: 'https://picsum.photos/seed/kiran/200',
      scope: LeaderboardScope.clan, period: LeaderboardPeriod.alltime,
      rank: 3, compositeScore: 7100, totalFlags: 156, majorFlags: 10,
      countriesVisited: 2, continentsExplored: 1, completedTrips: 14,
      legendaryRallies: 4, communityContributions: 52, streakDays: 40,
    ),
    LeaderboardEntry(
      id: 'lb24', userId: 'u3', userName: 'Rahul Menon', userHandle: '@rahul_nomad',
      userAvatar: 'https://picsum.photos/seed/rahul/200',
      scope: LeaderboardScope.clan, period: LeaderboardPeriod.alltime,
      rank: 4, compositeScore: 6500, totalFlags: 189, majorFlags: 8,
      countriesVisited: 3, continentsExplored: 1, completedTrips: 7,
      legendaryRallies: 1, communityContributions: 22, streakDays: 12,
    ),
    LeaderboardEntry(
      id: 'lb25', userId: 'u6', userName: 'Anjali Varma', userHandle: '@anjali_coast',
      userAvatar: 'https://picsum.photos/seed/anjali/200',
      scope: LeaderboardScope.clan, period: LeaderboardPeriod.alltime,
      rank: 5, compositeScore: 6800, totalFlags: 134, majorFlags: 9,
      countriesVisited: 4, continentsExplored: 2, completedTrips: 8,
      legendaryRallies: 1, communityContributions: 33, streakDays: 15,
    ),
  ];

  // ─── Notifications ───────────────────────────────────────────────────
  List<NotificationItem> get notifications => _notifications;

  static final List<NotificationItem> _notifications = [
    NotificationItem(
      id: 'notif1',
      type: NotificationType.friendRequest,
      title: 'Friend Request',
      body: 'Lakshmi Raj wants to be your travel buddy.',
      targetId: 'u10',
      targetType: 'user',
      isRead: false,
      createdAt: DateTime(2026, 11, 14, 10, 0),
    ),
    NotificationItem(
      id: 'notif2',
      type: NotificationType.tripInvite,
      title: 'Trip Invite',
      body: 'Kiran Das invited you to the Wayanad Waterfall Circuit trip.',
      targetId: 'trip1',
      targetType: 'trip',
      isRead: false,
      createdAt: DateTime(2026, 11, 13, 20, 0),
    ),
    NotificationItem(
      id: 'notif3',
      type: NotificationType.rallyAlert,
      title: 'Rally Alert',
      body: 'Munnar Sunrise Rally is happening in 2 days! Be at Top Station by 5 AM.',
      targetId: 'rally1',
      targetType: 'rally',
      isRead: false,
      createdAt: DateTime(2026, 11, 14, 8, 0),
    ),
    NotificationItem(
      id: 'notif4',
      type: NotificationType.kudos,
      title: 'Kudos Received!',
      body: 'Meera Krishnan gave you Epic kudos on your Lockhart Gap flag.',
      targetId: 'f_user_1',
      targetType: 'flag',
      isRead: true,
      createdAt: DateTime(2026, 11, 14, 7, 0),
    ),
    NotificationItem(
      id: 'notif5',
      type: NotificationType.leaderboardChange,
      title: 'Rank Up!',
      body: 'You moved up to #1 on the Kerala Explorers clan leaderboard!',
      targetId: 'clan1',
      targetType: 'clan',
      isRead: true,
      createdAt: DateTime(2026, 11, 13, 18, 30),
    ),
    NotificationItem(
      id: 'notif6',
      type: NotificationType.communityInvite,
      title: 'Community Invite',
      body: 'Anjali Varma invited you to join Varkala-Kovalam Surf Club.',
      targetId: 'com5',
      targetType: 'community',
      isRead: false,
      createdAt: DateTime(2026, 11, 12, 15, 0),
    ),
    NotificationItem(
      id: 'notif7',
      type: NotificationType.tripVoteResult,
      title: 'Trip Vote Result',
      body: 'Munnar to Kodaikanal Ridge Run reached 14 upvotes and is now the top plan!',
      targetId: 'tp1',
      targetType: 'trip_plan',
      isRead: true,
      createdAt: DateTime(2026, 11, 11, 12, 0),
    ),
    NotificationItem(
      id: 'notif8',
      type: NotificationType.flagNearby,
      title: 'Flag Nearby',
      body: 'Rahul Menon dropped a flag 500m from your location at Top Station.',
      targetId: 'f_nearby_1',
      targetType: 'flag',
      isRead: false,
      createdAt: DateTime(2026, 11, 14, 15, 10),
    ),
  ];

  // ─── Convenience Queries ─────────────────────────────────────────────

  List<Community> communitiesByClan(String clanId) =>
      _communities.where((c) => c.parentClanId == clanId).toList();

  Community? communityById(String id) {
    try {
      return _communities.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  Clan? clanById(String id) {
    try {
      return _clans.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  User? userById(String id) {
    try {
      return _users.firstWhere((u) => u.id == id);
    } catch (_) {
      return null;
    }
  }

  List<CommunityMessage> messagesByCommunity(String communityId) =>
      _communityMessages.where((m) => m.communityId == communityId).toList();

  List<CommunityActivity> activitiesByCommunity(String communityId) =>
      _communityActivities
          .where((a) => a.communityId == communityId)
          .toList();

  List<FriendRelationship> friendsForUser(String userId) =>
      _friendRelationships
          .where((f) =>
              (f.userId == userId || f.friendId == userId) &&
              f.status == FriendStatus.accepted)
          .toList();

  List<FriendRelationship> friendRequestsForUser(String userId) =>
      _friendRelationships
          .where((f) => f.friendId == userId && f.status == FriendStatus.pending)
          .toList();

  List<LeaderboardEntry> leaderboard(
          LeaderboardScope scope, LeaderboardPeriod period) =>
      _leaderboardEntries
          .where((e) => e.scope == scope && e.period == period)
          .toList()
        ..sort((a, b) => a.rank.compareTo(b.rank));

  List<NotificationItem> get unreadNotifications =>
      _notifications.where((n) => !n.isRead).toList();

  List<TripPlan> get savedPlans =>
      _tripPlans.where((tp) => tp.status == TripPlanStatus.draft).toList();

  List<Trip> get completedTrips =>
      _activeTrips.where((t) => t.status == TripStatus.completed).toList();
}
