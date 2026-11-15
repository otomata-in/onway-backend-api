const cron = require('node-cron');
const prisma = require('../config/prisma');

function startCronJobs() {
  // Run every 15 minutes
  cron.schedule('*/15 * * * *', async () => {
    try {
      console.log('⏰ Running Teritory Trip Expiry & Validation Auditor...');
      const now = new Date();

      const expiredTrips = await prisma.trip.findMany({
        where: {
          status: 'ACTIVE',
          expiresAt: { lt: now },
        },
        include: {
          tripPlan: { include: { waypoints: { orderBy: { orderIndex: 'desc' } } } },
          participants: true,
        },
      });

      for (const trip of expiredTrips) {
        const destWaypoint = trip.tripPlan.waypoints[0]; // Last ordered waypoint

        for (const p of trip.participants) {
          let hasDestValidation = false;
          if (destWaypoint) {
            const destCheck = await prisma.waypointValidation.findFirst({
              where: {
                tripId: trip.id,
                waypointId: destWaypoint.id,
                userId: p.userId,
                isValid: true,
              },
            });
            hasDestValidation = !!destCheck;
          }

          if (hasDestValidation) {
            await prisma.tripParticipant.update({
              where: { id: p.id },
              data: { status: 'COMPLETED', badge: 'PARTIAL' },
            });
            await prisma.user.update({
              where: { id: p.userId },
              data: { completedTripsCount: { increment: 1 }, isTripMode: false },
            });
          } else {
            // "if they not flaged the trip destination vith in 15 km radious, erased from trip profilings"
            await prisma.tripParticipant.update({
              where: { id: p.id },
              data: { status: 'DROPPED', badge: 'NONE' },
            });
            await prisma.user.update({
              where: { id: p.userId },
              data: { isTripMode: false },
            });
          }
        }

        await prisma.trip.update({
          where: { id: trip.id },
          data: { status: 'EXPIRED' },
        });
      }
    } catch (err) {
      console.error('Error in tripExpiry cron job:', err);
    }
  });

  console.log('⏳ Background Cron Jobs initialized.');
}

module.exports = { startCronJobs };
