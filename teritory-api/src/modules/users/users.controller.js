const prisma = require('../../config/prisma');
const ApiResponse = require('../../utils/ApiResponse');
const ApiError = require('../../utils/ApiError');
const { normalizeFlagStyle } = require('../flags/flag_style');

/**
 * Enriches user object with real-time relational counts to eliminate drift
 * between denormalized columns and actual child rows.
 */
const enrichUserWithRealStats = async (user) => {
  if (!user) return user;
  const [flagsCount, majorFlagsCount, countries, continents, completedTrips] = await Promise.all([
    prisma.flag.count({ where: { userId: user.id } }),
    prisma.flag.count({ where: { userId: user.id, isMajorFlag: true } }),
    prisma.flag.findMany({ where: { userId: user.id }, select: { country: true }, distinct: ['country'] }),
    prisma.flag.findMany({ where: { userId: user.id }, select: { continent: true }, distinct: ['continent'] }),
    prisma.tripParticipant.count({ where: { userId: user.id, status: 'COMPLETED' } }),
  ]);

  const totalFlags = flagsCount;
  const majorFlags = majorFlagsCount;
  const countriesVisited = countries.length;
  const continentsVisited = continents.length;
  const completedTripsCount = completedTrips;

  if (
    user.totalFlags !== totalFlags ||
    user.majorFlags !== majorFlags ||
    user.countriesVisited !== countriesVisited ||
    user.continentsVisited !== continentsVisited ||
    user.completedTripsCount !== completedTripsCount
  ) {
    prisma.user.update({
      where: { id: user.id },
      data: { totalFlags, majorFlags, countriesVisited, continentsVisited, completedTripsCount },
    }).catch(() => {});
  }

  return {
    ...user,
    totalFlags,
    majorFlags,
    countriesVisited,
    continentsVisited,
    completedTripsCount,
  };
};

// Get current user profile
const getMyProfile = async (req, res, next) => {
  try {
    const user = await prisma.user.findUnique({
      where: { id: req.user.id },
      include: {
        passportStamps: true,
      },
    });
    const enriched = await enrichUserWithRealStats(user);
    return ApiResponse.success(res, enriched);
  } catch (err) {
    next(err);
  }
};

// Update profile details
const updateMyProfile = async (req, res, next) => {
  try {
    const allowed = ['displayName', 'bio', 'avatarUrl', 'coverImageUrl', 'country', 'state', 'district', 'mapStyle', 'isPrivate', 'fcmToken'];
    const updateData = {};
    for (const key of allowed) {
      if (req.body[key] !== undefined) updateData[key] = req.body[key];
    }

    const updated = await prisma.user.update({
      where: { id: req.user.id },
      data: updateData,
    });
    return ApiResponse.success(res, updated, 'Profile updated successfully');
  } catch (err) {
    next(err);
  }
};

// Save the traveller's signature flag.
//
// Kept separate from PATCH /users/me so a profile edit and a style edit can
// never overwrite each other, and so the style has one validator.
const updateMyFlagStyle = async (req, res, next) => {
  try {
    const style = req.body?.style;
    if (style === undefined || style === null) {
      throw ApiError.badRequest('A flag style is required');
    }

    const normalized = normalizeFlagStyle(style);
    const updated = await prisma.user.update({
      where: { id: req.user.id },
      data: { flagStyle: normalized },
      select: { flagStyle: true },
    });

    return ApiResponse.success(
      res,
      { flagStyle: updated.flagStyle },
      'Flag style saved'
    );
  } catch (err) {
    next(err);
  }
};

// Toggle Trip Mode
const toggleTripMode = async (req, res, next) => {
  try {
    const { isTripMode } = req.body;
    const updated = await prisma.user.update({
      where: { id: req.user.id },
      data: { isTripMode: isTripMode !== undefined ? isTripMode : !req.user.isTripMode },
    });
    return ApiResponse.success(res, { isTripMode: updated.isTripMode }, 'Trip mode updated');
  } catch (err) {
    next(err);
  }
};

// Get public user profile
const getUserProfile = async (req, res, next) => {
  try {
    const { userId } = req.params;
    const currentUserId = req.user?.id;

    const user = await prisma.user.findUnique({
      where: { id: userId },
      include: {
        passportStamps: true,
        clanMemberships: {
          include: {
            clan: {
              select: {
                id: true,
                name: true,
                interestTag: true,
                coverImageUrl: true,
                region: true,
                memberCount: true,
              },
            },
          },
        },
      },
    });

    if (!user) {
      throw ApiError.notFound('User profile not found');
    }

    const enriched = await enrichUserWithRealStats(user);

    // Format clans
    const clans = (user.clanMemberships || []).map((cm) => ({
      id: cm.clan.id,
      name: cm.clan.name,
      tag: cm.clan.interestTag || '',
      avatarUrl: cm.clan.coverImageUrl || '',
      category: cm.clan.interestTag || cm.clan.region || 'General',
      role: cm.role,
      memberCount: cm.clan.memberCount,
    }));

    // Relationship & Mutuals with requesting user
    let relationship = {
      status: currentUserId === userId ? 'SELF' : 'NONE',
      relationshipId: null,
    };
    let mutualFriends = [];
    let mutualExploredAreas = {
      commonCountries: [],
      commonStates: [],
      commonContinents: [],
    };

    if (currentUserId && currentUserId !== userId) {
      // 1. Direct relationship
      const directRel = await prisma.friendRelationship.findFirst({
        where: {
          OR: [
            { senderId: currentUserId, receiverId: userId },
            { senderId: userId, receiverId: currentUserId },
          ],
        },
      });

      if (directRel) {
        if (directRel.status === 'ACCEPTED') {
          relationship = {
            status: 'FRIENDS',
            relationshipId: directRel.id,
            category: directRel.category,
            since: directRel.since,
          };
        } else if (directRel.status === 'PENDING') {
          relationship = {
            status: directRel.senderId === currentUserId ? 'REQUEST_SENT' : 'REQUEST_RECEIVED',
            relationshipId: directRel.id,
            category: directRel.category,
            since: directRel.since,
          };
        }
      }

      // 2. Mutual Friends
      const [myFriends, targetFriends] = await Promise.all([
        prisma.friendRelationship.findMany({
          where: {
            status: 'ACCEPTED',
            OR: [{ senderId: currentUserId }, { receiverId: currentUserId }],
          },
          select: { senderId: true, receiverId: true },
        }),
        prisma.friendRelationship.findMany({
          where: {
            status: 'ACCEPTED',
            OR: [{ senderId: userId }, { receiverId: userId }],
          },
          select: { senderId: true, receiverId: true },
        }),
      ]);

      const myFriendIds = new Set(
        myFriends.map((r) => (r.senderId === currentUserId ? r.receiverId : r.senderId))
      );
      const targetFriendIds = new Set(
        targetFriends.map((r) => (r.senderId === userId ? r.receiverId : r.senderId))
      );

      const mutualIds = [...myFriendIds].filter((id) => targetFriendIds.has(id));

      if (mutualIds.length > 0) {
        mutualFriends = await prisma.user.findMany({
          where: { id: { in: mutualIds } },
          select: {
            id: true,
            displayName: true,
            handle: true,
            avatarUrl: true,
          },
          take: 10,
        });
      }

      // 3. Mutual Explored Areas (common territories)
      const [myFlags, targetFlags] = await Promise.all([
        prisma.flag.findMany({
          where: { userId: currentUserId },
          select: { country: true, city: true, continent: true },
        }),
        prisma.flag.findMany({
          where: { userId },
          select: { country: true, city: true, continent: true },
        }),
      ]);

      const myCountries = new Set(myFlags.map((f) => f.country?.trim()).filter(Boolean));
      const targetCountries = new Set(targetFlags.map((f) => f.country?.trim()).filter(Boolean));
      const commonCountries = [...myCountries].filter((c) => targetCountries.has(c));

      const myCities = new Set(myFlags.map((f) => f.city?.trim()).filter(Boolean));
      const targetCities = new Set(targetFlags.map((f) => f.city?.trim()).filter(Boolean));
      const commonCities = [...myCities].filter((c) => targetCities.has(c));

      const myContinents = new Set(myFlags.map((f) => f.continent?.trim()).filter(Boolean));
      const targetContinents = new Set(targetFlags.map((f) => f.continent?.trim()).filter(Boolean));
      const commonContinents = [...myContinents].filter((c) => targetContinents.has(c));

      mutualExploredAreas = {
        commonCountries,
        commonStates: commonCities,
        commonCities,
        commonContinents,
      };
    }

    return ApiResponse.success(res, {
      ...enriched,
      clans,
      relationship,
      mutualFriends,
      mutualExploredAreas,
    });
  } catch (err) {
    next(err);
  }
};

// Get Friends List
const getFriends = async (req, res, next) => {
  try {
    const { category } = req.query;
    const currentUserId = req.user.id;

    const relationships = await prisma.friendRelationship.findMany({
      where: {
        status: 'ACCEPTED',
        OR: [{ senderId: currentUserId }, { receiverId: currentUserId }],
        ...(category ? { category } : {}),
      },
      include: {
        sender: true,
        receiver: true,
      },
    });

    const friends = relationships.map((rel) => {
      const isSender = rel.senderId === currentUserId;
      const friendUser = isSender ? rel.receiver : rel.sender;
      return {
        ...friendUser,
        relationshipId: rel.id,
        category: rel.category,
        since: rel.since,
      };
    });

    return ApiResponse.success(res, friends);
  } catch (err) {
    next(err);
  }
};

// Pending friend requests, split into what the caller received and what they sent
const getFriendRequests = async (req, res, next) => {
  try {
    const currentUserId = req.user.id;

    const relationships = await prisma.friendRelationship.findMany({
      where: {
        status: 'PENDING',
        OR: [{ senderId: currentUserId }, { receiverId: currentUserId }],
      },
      include: { sender: true, receiver: true },
      orderBy: { since: 'desc' },
    });

    const shape = (rel) => {
      const isIncoming = rel.receiverId === currentUserId;
      const otherUser = isIncoming ? rel.sender : rel.receiver;
      return {
        ...otherUser,
        relationshipId: rel.id,
        category: rel.category,
        since: rel.since,
        direction: isIncoming ? 'INCOMING' : 'OUTGOING',
      };
    };

    const incoming = relationships
      .filter((rel) => rel.receiverId === currentUserId)
      .map(shape);
    const outgoing = relationships
      .filter((rel) => rel.senderId === currentUserId)
      .map(shape);

    return ApiResponse.success(res, { incoming, outgoing });
  } catch (err) {
    next(err);
  }
};

// Cancel a friend request the caller sent
const cancelFriendRequest = async (req, res, next) => {
  try {
    const { id } = req.params;
    const rel = await prisma.friendRelationship.findUnique({ where: { id } });

    if (!rel || rel.senderId !== req.user.id) {
      throw ApiError.notFound('Friend request not found');
    }
    if (rel.status !== 'PENDING') {
      throw ApiError.badRequest('Only pending requests can be cancelled');
    }

    await prisma.friendRelationship.delete({ where: { id } });
    return ApiResponse.success(res, { cancelled: true }, 'Friend request cancelled');
  } catch (err) {
    next(err);
  }
};

// Remove an accepted friend
const removeFriend = async (req, res, next) => {
  try {
    const { id } = req.params;
    const rel = await prisma.friendRelationship.findUnique({ where: { id } });

    if (
      !rel ||
      (rel.senderId !== req.user.id && rel.receiverId !== req.user.id)
    ) {
      throw ApiError.notFound('Friendship not found');
    }
    if (rel.status !== 'ACCEPTED') {
      throw ApiError.badRequest('Only accepted friendships can be removed');
    }

    await prisma.friendRelationship.delete({ where: { id } });
    return ApiResponse.success(res, { removed: true }, 'Friend removed');
  } catch (err) {
    next(err);
  }
};

// Search users by name or handle
const searchUsers = async (req, res, next) => {
  try {
    const { q = '' } = req.query;
    if (!q.trim()) {
      return ApiResponse.success(res, []);
    }
    const query = q.trim();
    const users = await prisma.user.findMany({
      where: {
        id: { not: req.user.id },
        OR: [
          { displayName: { contains: query, mode: 'insensitive' } },
          { handle: { contains: query, mode: 'insensitive' } },
        ],
      },
      select: {
        id: true,
        displayName: true,
        handle: true,
        avatarUrl: true,
        totalFlags: true,
        completedTripsCount: true,
        state: true,
        district: true,
        isPrivate: true,
      },
      take: 20,
    });
    return ApiResponse.success(res, users);
  } catch (err) {
    next(err);
  }
};

// Invite friends (multi-select) to a clan, community, trip, or rally
const inviteFriends = async (req, res, next) => {
  try {
    const { targetUserIds = [], type = 'COMMUNITY', targetId, title, message } = req.body;
    if (!Array.isArray(targetUserIds) || targetUserIds.length === 0) {
      throw ApiError.badRequest('At least one friend must be selected');
    }

    const typeMap = {
      CLAN: 'CLAN_INVITE',
      COMMUNITY: 'COMMUNITY_INVITE',
      TRIP: 'TRIP_INVITE',
      RALLY: 'RALLY_INVITE',
    };
    const key = String(type).toUpperCase();
    const notifType = typeMap[key];
    if (!notifType) {
      throw ApiError.badRequest(`Unsupported invite type: ${type}`);
    }
    if (!targetId) {
      throw ApiError.badRequest(`A targetId is required for ${key} invites`);
    }

    // A bad target used to be reported as a successful invite that deep-linked
    // nowhere; resolve it first and let a missing target be a 404.
    const targetExists = async () => {
      if (key === 'CLAN') {
        return Boolean(await prisma.clan.findUnique({ where: { id: targetId }, select: { id: true } }));
      }
      if (key === 'TRIP') {
        return Boolean(await prisma.tripPlan.findUnique({ where: { id: targetId }, select: { id: true } }));
      }
      if (key === 'RALLY') {
        return Boolean(await prisma.legendaryRally.findUnique({ where: { id: targetId }, select: { id: true } }));
      }
      return Boolean(await prisma.community.findUnique({ where: { id: targetId }, select: { id: true } }));
    };
    if (!(await targetExists())) {
      throw ApiError.notFound(`${key} target not found`);
    }

    // Build paths the mobile router can resolve, not bare ids.
    let actionUrl = '/notifications';
    if (key === 'CLAN') {
      actionUrl = `/clans/${targetId}`;
    } else if (key === 'TRIP') {
      actionUrl = `/trips/${targetId}`;
    } else if (key === 'COMMUNITY') {
      const community = await prisma.community.findUnique({
        where: { id: targetId },
        select: { parentClanId: true },
      });
      actionUrl = community
        ? `/clans/${community.parentClanId}/communities/${targetId}`
        : '/notifications';
    }

    const notifications = targetUserIds.map((userId) => ({
      userId,
      type: notifType,
      title: title || `${req.user.displayName} invited you!`,
      body: message || `${req.user.displayName} invited you to join a ${type}.`,
      actionUrl,
    }));

    await prisma.notification.createMany({
      data: notifications,
    });

    return ApiResponse.success(res, { invitedCount: targetUserIds.length }, 'Invitations sent successfully');
  } catch (err) {
    next(err);
  }
};

// Send Friend Request
const sendFriendRequest = async (req, res, next) => {
  try {
    const { targetUserId, category } = req.body;
    if (targetUserId === req.user.id) {
      throw ApiError.badRequest('Cannot send friend request to yourself');
    }

    const existing = await prisma.friendRelationship.findFirst({
      where: {
        OR: [
          { senderId: req.user.id, receiverId: targetUserId },
          { senderId: targetUserId, receiverId: req.user.id },
        ],
      },
    });

    if (existing) {
      if (existing.status === 'ACCEPTED') {
        throw ApiError.badRequest('You are already friends');
      }
      throw ApiError.badRequest('Friend request already pending');
    }

    const rel = await prisma.friendRelationship.create({
      data: {
        senderId: req.user.id,
        receiverId: targetUserId,
        status: 'PENDING',
        category: category || 'TRAVEL_BUDDIES',
      },
    });

    // Create notification
    await prisma.notification.create({
      data: {
        userId: targetUserId,
        type: 'FRIEND_REQUEST',
        title: 'New Friend Request',
        body: `${req.user.displayName} sent you a travel friend request`,
        actionUrl: `/profile/friend-requests`,
      },
    });

    return ApiResponse.created(res, rel, 'Friend request sent');
  } catch (err) {
    next(err);
  }
};

// Respond to friend request (ACCEPT / DECLINE)
const respondFriendRequest = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { action } = req.body; // 'ACCEPT' or 'DECLINE'

    const rel = await prisma.friendRelationship.findUnique({
      where: { id },
    });

    if (!rel || rel.receiverId !== req.user.id) {
      throw ApiError.notFound('Friend request not found');
    }

    if (action === 'ACCEPT') {
      const updated = await prisma.friendRelationship.update({
        where: { id },
        data: { status: 'ACCEPTED' },
      });

      // Notify sender
      await prisma.notification.create({
        data: {
          userId: rel.senderId,
          type: 'FRIEND_ACCEPTED',
          title: 'Friend Request Accepted',
          body: `${req.user.displayName} accepted your friend request!`,
          actionUrl: `/profile/friends`,
        },
      });

      return ApiResponse.success(res, updated, 'Friend request accepted');
    } else {
      await prisma.friendRelationship.update({
        where: { id },
        data: { status: 'DECLINED' },
      });
      return ApiResponse.success(res, { declined: true }, 'Friend request declined');
    }
  } catch (err) {
    next(err);
  }
};

// Permanently delete own account (revokes tokens, removes friendships, soft-deletes profile)
const deleteMyAccount = async (req, res, next) => {
  try {
    const userId = req.user.id;

    // Revoke refresh tokens
    await prisma.refreshToken.deleteMany({ where: { userId } });

    // Remove friendship relationships
    await prisma.friendRelationship.deleteMany({
      where: {
        OR: [{ senderId: userId }, { receiverId: userId }],
      },
    });

    // Remove clan & community memberships
    await prisma.clanMember.deleteMany({ where: { userId } });
    await prisma.communityMember.deleteMany({ where: { userId } });

    // Clean notifications
    await prisma.notification.deleteMany({ where: { userId } });

    // Soft-delete user row to maintain FK integrity with existing flags/waypoints
    await prisma.user.update({
      where: { id: userId },
      data: {
        isActive: false,
        displayName: 'Deleted Traveler',
        handle: `deleted_${userId.substring(0, 8)}`,
        bio: '',
        phone: null,
        email: null,
        avatarUrl: null,
        coverImageUrl: null,
      },
    });

    return ApiResponse.success(res, { deleted: true }, 'Account successfully deleted');
  } catch (err) {
    next(err);
  }
};

module.exports = {
  getMyProfile,
  updateMyProfile,
  updateMyFlagStyle,
  toggleTripMode,
  getUserProfile,
  getFriends,
  getFriendRequests,
  cancelFriendRequest,
  removeFriend,
  searchUsers,
  inviteFriends,
  sendFriendRequest,
  respondFriendRequest,
  deleteMyAccount,
};

