const { Vendor } = require('../models');
const redis = require('../config/redis');

/**
 * Batch Location Sync
 *
 * Periodically syncs vendor locations from Redis to MySQL.
 * This reduces DB writes during high-frequency location updates.
 *
 * Flow:
 *   Socket/REST location_update → Redis (immediate)
 *   Batch sync (periodic) → MySQL (every N seconds)
 */

const SYNC_INTERVAL_MS = 30000; // Sync every 30 seconds
let syncTimer = null;

const locationSync = {
  /**
   * Start the periodic sync process
   */
  start() {
    if (syncTimer) return; // Already running

    syncTimer = setInterval(() => {
      this.syncAll().catch((err) => {
        console.error('Location batch sync error:', err.message);
      });
    }, SYNC_INTERVAL_MS);

    console.log(`✅ Location batch sync started (every ${SYNC_INTERVAL_MS / 1000}s)`);
  },

  /**
   * Stop the periodic sync
   */
  stop() {
    if (syncTimer) {
      clearInterval(syncTimer);
      syncTimer = null;
      console.log('🔌 Location batch sync stopped');
    }
  },

  /**
   * Sync all cached vendor locations from Redis to MySQL
   */
  async syncAll() {
    try {
      if (redis.status !== 'ready') return;

      // Scan for all vendor location keys in Redis
      const keys = [];
      let cursor = '0';

      do {
        const [newCursor, batch] = await redis.scan(cursor, 'MATCH', 'vendor_location:*', 'COUNT', 100);
        cursor = newCursor;
        keys.push(...batch);
      } while (cursor !== '0');

      if (keys.length === 0) return;

      // Batch update DB
      let synced = 0;
      for (const key of keys) {
        try {
          const cached = await redis.hgetall(key);
          if (!cached || !cached.lat || !cached.lng) continue;

          const vendorId = parseInt(key.split(':')[1], 10);
          if (isNaN(vendorId)) continue;

          await Vendor.update(
            {
              lat: parseFloat(cached.lat),
              lng: parseFloat(cached.lng),
            },
            { where: { id: vendorId } }
          );

          synced++;
        } catch (err) {
          // Skip individual vendor errors
          console.error(`Sync error for ${key}:`, err.message);
        }
      }

      if (synced > 0) {
        console.log(`📍 Batch synced ${synced} vendor locations to DB`);
      }
    } catch (error) {
      console.error('Batch sync error:', error.message);
    }
  },
};

module.exports = locationSync;
