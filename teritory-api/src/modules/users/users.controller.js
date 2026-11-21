const prisma = require('../../config/prisma');
const ApiResponse = require('../../utils/ApiResponse');
const ApiError = require('../../utils/ApiError');

// Get current user profile
const getMyProfile = async (req, res, next) => {
  try {
    const user = await prisma.user.findUnique({
      where: { id: req.user.id },
      include: {
        passportStamps: true,
      },
    });
    return ApiResponse.success(res, user);
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
    const user = await prisma.user.findUnique({
      where: { id: userId },
      include: {
        passportStamps: true,
      },
    });

    if (!user) {
      throw ApiError.notFound('User profile not found');
    }

    return ApiResponse.success(res, user);
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

