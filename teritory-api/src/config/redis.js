const Redis = require('ioredis');

class InMemoryRedis {
  constructor() {
    this.store = new Map();
    this.sortedSets = new Map();
    console.log('⚡ Teritory In-Memory Cache initialized (Standalone dev mode)');
  }

  async get(key) {
    return this.store.get(key) || null;
  }

  async set(key, value, mode, duration) {
    this.store.set(key, value);
    if (mode === 'EX' && duration) {
      setTimeout(() => this.store.delete(key), duration * 1000);
    }
    return 'OK';
  }

  async del(key) {
    return this.store.delete(key) ? 1 : 0;
  }

  async zadd(key, score, member) {
    if (!this.sortedSets.has(key)) {
      this.sortedSets.set(key, new Map());
    }
    this.sortedSets.get(key).set(member, parseFloat(score));
    return 1;
  }

  async zrevrange(key, start, stop, withScores) {
    if (!this.sortedSets.has(key)) return [];
    const entries = Array.from(this.sortedSets.get(key).entries())
      .sort((a, b) => b[1] - a[1]);
    const sliced = entries.slice(start, stop === -1 ? undefined : stop + 1);
    if (withScores === 'WITHSCORES') {
      const res = [];
      for (const [member, score] of sliced) {
        res.push(member, score.toString());
      }
      return res;
    }
    return sliced.map(e => e[0]);
  }

  async zrevrank(key, member) {
    if (!this.sortedSets.has(key)) return null;
    const entries = Array.from(this.sortedSets.get(key).entries())
      .sort((a, b) => b[1] - a[1]);
    const idx = entries.findIndex(e => e[0] === member);
    return idx === -1 ? null : idx;
  }

  async zscore(key, member) {
    if (!this.sortedSets.has(key)) return null;
    const score = this.sortedSets.get(key).get(member);
    return score !== undefined ? score.toString() : null;
  }
}

let redisClient;

if (process.env.REDIS_URL) {
  try {
    redisClient = new Redis(process.env.REDIS_URL, {
      maxRetriesPerRequest: 1,
      lazyConnect: true,
    });
    redisClient.on('connect', () => console.log('✅ Connected to external Redis'));
    redisClient.on('error', (err) => console.warn('⚠️ Redis error:', err.message));
  } catch (err) {
    console.warn('⚠️ Falling back to in-memory cache:', err.message);
    redisClient = new InMemoryRedis();
  }
} else {
  redisClient = new InMemoryRedis();
}

module.exports = redisClient;

