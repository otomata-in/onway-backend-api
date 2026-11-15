const prisma = require('../../config/prisma');
const ApiResponse = require('../../utils/ApiResponse');
const ApiError = require('../../utils/ApiError');

const createCommunity = async (req, res, next) => {
  try {
    const { name, description = '', coverImageUrl, parentClanId, interestTags = [], isPublic = true } = req.body;
    if (!name || !parentClanId) throw ApiError.badRequest('Name and parent clan ID required');

    const community = await prisma.community.create({
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
    });

    await prisma.clan.update({
      where: { id: parentClanId },
      data: { communitiesCount: { increment: 1 } },
    });

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
      },
      orderBy: { createdAt: 'desc' },
    });
    return ApiResponse.success(res, plans);
  } catch (err) {
    next(err);
  }
};

module.exports = {
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
