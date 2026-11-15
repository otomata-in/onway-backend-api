const prisma = require('../../config/prisma');
const ApiResponse = require('../../utils/ApiResponse');
const ApiError = require('../../utils/ApiError');

const getClans = async (req, res, next) => {
  try {
    const { search, region } = req.query;
    const where = {};

    if (search) {
      where.OR = [
        { name: { contains: search, mode: 'insensitive' } },
        { description: { contains: search, mode: 'insensitive' } },
      ];
    }
    if (region) {
      where.region = { contains: region, mode: 'insensitive' };
    }

    const clans = await prisma.clan.findMany({
      where,
      include: {
        chieftain: { select: { id: true, displayName: true, avatarUrl: true } },
        _count: { select: { members: true, communities: true } },
      },
    });

    return ApiResponse.success(res, clans);
  } catch (err) {
    next(err);
  }
};

const getMyClans = async (req, res, next) => {
  try {
    const memberships = await prisma.clanMember.findMany({
      where: { userId: req.user.id },
      include: {
        clan: {
          include: {
            chieftain: { select: { id: true, displayName: true, avatarUrl: true } },
          },
        },
      },
    });

    const clans = memberships.map((m) => ({
      ...m.clan,
      myRole: m.role,
      joinedAt: m.joinedAt,
    }));

    return ApiResponse.success(res, clans);
  } catch (err) {
    next(err);
  }
};

const createClan = async (req, res, next) => {
  try {
    const { name, description = '', coverImageUrl, region = '', interestTag = '' } = req.body;
    if (!name) throw ApiError.badRequest('Clan name is required');

    const clan = await prisma.clan.create({
      data: {
        name,
        description,
        coverImageUrl,
        region,
        interestTag,
        chieftainId: req.user.id,
        memberCount: 1,
        members: {
          create: {
            userId: req.user.id,
            role: 'CHIEFTAIN',
          },
        },
      },
    });

    return ApiResponse.created(res, clan, 'Clan founded successfully!');
  } catch (err) {
    next(err);
  }
};

const getClanById = async (req, res, next) => {
  try {
    const { clanId } = req.params;
    const clan = await prisma.clan.findUnique({
      where: { id: clanId },
      include: {
        chieftain: { select: { id: true, displayName: true, avatarUrl: true, handle: true } },
        communities: {
          include: {
            _count: { select: { members: true, tripPlans: true } },
          },
        },
        members: {
          include: {
            user: { select: { id: true, displayName: true, avatarUrl: true, handle: true } },
          },
          take: 20,
        },
      },
    });

    if (!clan) throw ApiError.notFound('Clan not found');

    return ApiResponse.success(res, clan);
  } catch (err) {
    next(err);
  }
};

const joinClan = async (req, res, next) => {
  try {
    const { clanId } = req.params;
    const existing = await prisma.clanMember.findUnique({
      where: { clanId_userId: { clanId, userId: req.user.id } },
    });

    if (existing) throw ApiError.badRequest('Already a member of this clan');

    const member = await prisma.clanMember.create({
      data: {
        clanId,
        userId: req.user.id,
        role: 'MEMBER',
      },
    });

    await prisma.clan.update({
      where: { id: clanId },
      data: { memberCount: { increment: 1 } },
    });

    return ApiResponse.created(res, member, 'Joined clan successfully');
  } catch (err) {
    next(err);
  }
};

const leaveClan = async (req, res, next) => {
  try {
    const { clanId } = req.params;
    await prisma.clanMember.delete({
      where: { clanId_userId: { clanId, userId: req.user.id } },
    });

    await prisma.clan.update({
      where: { id: clanId },
      data: { memberCount: { decrement: 1 } },
    });

    return ApiResponse.success(res, { left: true }, 'Left clan');
  } catch (err) {
    next(err);
  }
};

const getClanCommunities = async (req, res, next) => {
  try {
    const { clanId } = req.params;
    const communities = await prisma.community.findMany({
      where: { parentClanId: clanId },
      include: {
        _count: { select: { members: true, tripPlans: true } },
      },
    });
    return ApiResponse.success(res, communities);
  } catch (err) {
    next(err);
  }
};

module.exports = {
  getClans,
  getMyClans,
  createClan,
  getClanById,
  joinClan,
  leaveClan,
  getClanCommunities,
};
