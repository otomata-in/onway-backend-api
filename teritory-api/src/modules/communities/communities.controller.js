const prisma = require('../../config/prisma');
const ApiResponse = require('../../utils/ApiResponse');
const ApiError = require('../../utils/ApiError');
const { notifyMany } = require('../notifications/notifications.service');

const listCommunities = async (req, res, next) => {
  try {
    const { clanId, tag, search } = req.query;
    const where = {};
    if (clanId) where.parentClanId = clanId;
    if (tag) where.interestTags = { has: tag };
    if (search) {
      where.OR = [
        { name: { contains: search, mode: 'insensitive' } },
        { description: { contains: search, mode: 'insensitive' } },
      ];
    }
    const communities = await prisma.community.findMany({
      where,
      include: {
        clan: { select: { id: true, name: true } },
        _count: { select: { members: true, tripPlans: true } },
      },
      orderBy: { memberCount: 'desc' },
    });
    return ApiResponse.success(res, communities);
  } catch (err) {
    next(err);
  }
};

const createCommunity = async (req, res, next) => {
  try {
    const { name, description = '', coverImageUrl, parentClanId, interestTags = [], isPublic = true } = req.body;
    if (!name || !parentClanId) throw ApiError.badRequest('Name and parent clan ID required');

    // Validate the parent clan up front so a bad id is a 404 instead of a
    // foreign-key violation bubbling out of Prisma as a 500.
    const clan = await prisma.clan.findUnique({
      where: { id: parentClanId },
      select: { id: true, chieftainId: true },
    });
    if (!clan) throw ApiError.notFound('Parent clan not found');

    // A community belongs to a clan its founder is actually part of: otherwise
    // anyone could attach a community to somebody else's clan.
    const isChieftain = clan.chieftainId === req.user.id;
    const membership = isChieftain
      ? null
      : await prisma.clanMember.findUnique({
          where: { clanId_userId: { clanId: parentClanId, userId: req.user.id } },
          select: { id: true },
        });
    if (!isChieftain && !membership) {
      throw ApiError.forbidden('Only members of this clan can found a community');
    }

    // The community and the clan's counter move together: a failed counter
    // update must not leave a community its clan does not count. Batched (not
    // interactive) so a slow database cannot trip the transaction timeout.
    const [community] = await prisma.$transaction([
      prisma.community.create({
        data: {
          name,
          description,
          coverImageUrl,
          parentClanId,
          interestTags,
          isPublic,
          memberCount: 1,
          members: {
            create: {
              userId: req.user.id,
              role: 'CREATOR',
            },
          },
        },
      }),
      prisma.clan.update({
        where: { id: parentClanId },
        data: { communitiesCount: { increment: 1 } },
      }),
    ]);

    return ApiResponse.created(res, community, 'Community founded');
  } catch (err) {
    next(err);
  }
};

const getCommunityById = async (req, res, next) => {
  try {
    const { id } = req.params;
    const community = await prisma.community.findUnique({
      where: { id },
      include: {
        clan: { select: { id: true, name: true, coverImageUrl: true } },
        _count: { select: { members: true, tripPlans: true, messages: true } },
      },
    });

    if (!community) throw ApiError.notFound('Community not found');

    return ApiResponse.success(res, community);
  } catch (err) {
    next(err);
  }
};

const joinCommunity = async (req, res, next) => {
  try {
    const { id } = req.params;
    const existing = await prisma.communityMember.findUnique({
      where: { communityId_userId: { communityId: id, userId: req.user.id } },
    });

    if (existing) throw ApiError.badRequest('Already a member of this community');

    const member = await prisma.communityMember.create({
      data: {
        communityId: id,
        userId: req.user.id,
        role: 'MEMBER',
      },
    });

    await prisma.community.update({
      where: { id },
      data: { memberCount: { increment: 1 } },
    });

    // Record activity
    await prisma.communityActivity.create({
      data: {
        communityId: id,
        userId: req.user.id,
        type: 'MEMBER_JOIN',
        title: 'New Member Joined',
        description: `${req.user.displayName} joined the community!`,
      },
    });

    // Tell the community's creators/moderators (never the joiner themselves).
    const community = await prisma.community.findUnique({
      where: { id },
      select: {
        name: true,
        parentClanId: true,
        members: {
          where: { role: { in: ['CREATOR', 'MODERATOR'] } },
          select: { userId: true },
        },
      },
    });

    await notifyMany(
      (community?.members || [])
        .filter((m) => m.userId !== req.user.id)
        .map((m) => ({
          userId: m.userId,
          type: 'SYSTEM',
          title: 'New community member',
          body: `${req.user.displayName} joined ${community.name}.`,
          icon: 'community',
          actionUrl: `/clans/${community.parentClanId}/communities/${id}`,
        })),
    );

    return ApiResponse.created(res, member, 'Joined community');
  } catch (err) {
    next(err);
  }
};

const leaveCommunity = async (req, res, next) => {
  try {
    const { id } = req.params;
    await prisma.communityMember.delete({
      where: { communityId_userId: { communityId: id, userId: req.user.id } },
    });

    await prisma.community.update({
      where: { id },
      data: { memberCount: { decrement: 1 } },
    });

    return ApiResponse.success(res, { left: true }, 'Left community');
  } catch (err) {
    next(err);
  }
};

const getCommunityFeed = async (req, res, next) => {
  try {
    const { id } = req.params;
    const activities = await prisma.communityActivity.findMany({
      where: { communityId: id },
      include: {
        user: { select: { id: true, displayName: true, avatarUrl: true } },
      },
      orderBy: { createdAt: 'desc' },
      take: 30,
    });
    return ApiResponse.success(res, activities);
  } catch (err) {
    next(err);
  }
};

const getCommunityMessages = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { limit = 50, before } = req.query;

    const where = { communityId: id };
    if (before) {
      where.createdAt = { lt: new Date(before) };
    }

    const messages = await prisma.communityMessage.findMany({
      where,
      include: {
        user: { select: { id: true, displayName: true, avatarUrl: true, handle: true } },
      },
      orderBy: { createdAt: 'desc' },
      take: parseInt(limit, 10),
    });

    return ApiResponse.success(res, messages.reverse());
  } catch (err) {
    next(err);
  }
};

const sendCommunityMessage = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { text } = req.body;

    if (!text || text.trim() === '') throw ApiError.badRequest('Message cannot be empty');

    const message = await prisma.communityMessage.create({
      data: {
        communityId: id,
        userId: req.user.id,
        text: text.trim(),
      },
      include: {
        user: { select: { id: true, displayName: true, avatarUrl: true, handle: true } },
      },
    });

    const io = req.app.get('io');
    if (io) {
      io.to(`community:${id}`).emit('new_message', message);
    }

    return ApiResponse.created(res, message);
  } catch (err) {
    next(err);
  }
};

const getCommunityMembers = async (req, res, next) => {
  try {
    const { id } = req.params;
    const members = await prisma.communityMember.findMany({
      where: { communityId: id },
      include: {
        user: { select: { id: true, displayName: true, avatarUrl: true, handle: true } },
      },
      orderBy: { joinedAt: 'asc' },
    });
    return ApiResponse.success(res, members);
  } catch (err) {
    next(err);
  }
};

const getCommunityTripPlans = async (req, res, next) => {
  try {
    const { id } = req.params;
    const plans = await prisma.tripPlan.findMany({
      where: { communityId: id },
      include: {
        waypoints: { orderBy: { orderIndex: 'asc' } },
        createdBy: { select: { id: true, displayName: true, avatarUrl: true } },
        community: { select: { id: true, name: true } },
      },
      orderBy: { createdAt: 'desc' },
    });
    return ApiResponse.success(res, plans);
  } catch (err) {
    next(err);
  }
};

module.exports = {
  listCommunities,
  createCommunity,
  getCommunityById,
  joinCommunity,
  leaveCommunity,
  getCommunityFeed,
  getCommunityMessages,
  sendCommunityMessage,
  getCommunityMembers,
  getCommunityTripPlans,
};

