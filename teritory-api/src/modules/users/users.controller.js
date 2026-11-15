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
    const allowed = ['displayName', 'bio', 'avatarUrl', 'coverImageUrl', 'country', 'state', 'district', 'mapStyle', 'isPrivate'];
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
    const notifType = typeMap[type.toUpperCase()] || 'COMMUNITY_INVITE';

    const notifications = targetUserIds.map((userId) => ({
      userId,
      type: notifType,
      title: title || `${req.user.displayName} invited you!`,
      body: message || `${req.user.displayName} invited you to join a ${type}.`,
      actionUrl: targetId ? `/${type.toLowerCase()}/${targetId}` : '/notifications',
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

module.exports = {
  getMyProfile,
  updateMyProfile,
  toggleTripMode,
  getUserProfile,
  getFriends,
  searchUsers,
  inviteFriends,
  sendFriendRequest,
  respondFriendRequest,
};

