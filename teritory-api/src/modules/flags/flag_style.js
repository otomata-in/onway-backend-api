const ApiError = require('../../utils/ApiError');

// The single source of truth for a flag's look on the server. Both the
// signature endpoint and flag creation go through normalizeFlagStyle, so the
// two can never accept a different vocabulary. The Flutter catalog mirrors
// these ids; flag_style_test.dart pins the client side.
const FLAG_STYLE_IDS = {
  // Blue leads: it is the product default. Coral stays legal for flags already
  // staked in it but no longer has any priority.
  theme: [
    'midnight_tide',
    'crimson_charge',
    'black_pirate',
    'neon_hacker',
    'rider_steel',
    'golden_summit',
    'emerald_trail',
    'sakura_dusk',
    'desert_mirage',
    'aurora',
    'monochrome_ink',
    'coral_expedition',
  ],
  pattern: [
    'solid',
    'horizon',
    'chevron',
    'tide',
    'sunburst',
    'constellation',
    'topographic',
    'weave',
  ],
  shape: ['classic', 'swallowtail', 'pennant', 'burgee'],
  emblem: [
    'none',
    'compass',
    'peak',
    'anchor',
    'star',
    'flame',
    'compass_rose',
    'paw',
    'skull',
    'terminal',
    'helmet',
    'bike_road',
    'bike_mountain',
    'bike_moto',
    'car_sedan',
    'car_suv',
    'car_sports',
  ],
  motion: [
    'still',
    'breeze',
    'gust',
    'ripple',
    'shimmer',
    'aurora',
    'storm',
    'inferno',
    'neon_pulse',
  ],
};

const MIN_SPEED = 0.5;
const MAX_SPEED = 2.0;

const DEFAULT_FLAG_STYLE = Object.freeze({
  v: 1,
  theme: 'midnight_tide',
  color: null,
  pattern: 'horizon',
  shape: 'classic',
  emblem: 'compass',
  motion: 'breeze',
  speed: 1,
});

const HEX_COLOR = /^#[0-9A-Fa-f]{6}$/;

const pickId = (input, field) => {
  const raw = input[field];
  if (raw === undefined || raw === null || raw === '') {
    return DEFAULT_FLAG_STYLE[field];
  }
  if (typeof raw !== 'string') {
    throw ApiError.badRequest(`Flag ${field} must be a string`);
  }
  const value = raw.trim().toLowerCase();
  if (!FLAG_STYLE_IDS[field].includes(value)) {
    throw ApiError.badRequest(
      `Unknown flag ${field} "${raw}". Allowed: ${FLAG_STYLE_IDS[field].join(', ')}`
    );
  }
  return value;
};

/**
 * Validates and canonicalises a style object.
 *
 * Unknown keys are dropped, ids are allowlisted, the colour is normalised to
 * uppercase #RRGGBB, speed is clamped to 0.5–2.0, and the version is always 1.
 * Anything unrecognisable is a 400 with a specific message, never a silent
 * fallback that would make a rejected style look saved.
 */
const normalizeFlagStyle = (input) => {
  if (input === null || input === undefined) {
    throw ApiError.badRequest('A flag style is required');
  }
  if (typeof input !== 'object' || Array.isArray(input)) {
    throw ApiError.badRequest('Flag style must be an object');
  }

  let color = null;
  const rawColor = input.color;
  if (rawColor !== undefined && rawColor !== null && rawColor !== '') {
    if (typeof rawColor !== 'string' || !HEX_COLOR.test(rawColor.trim())) {
      throw ApiError.badRequest('Flag colour must be a #RRGGBB hex value');
    }
    color = rawColor.trim().toUpperCase();
  }

  let speed = DEFAULT_FLAG_STYLE.speed;
  if (input.speed !== undefined && input.speed !== null) {
    const parsed = Number(input.speed);
    if (!Number.isFinite(parsed)) {
      throw ApiError.badRequest('Flag speed must be a number');
    }
    const clamped = Math.min(MAX_SPEED, Math.max(MIN_SPEED, parsed));
    speed = Math.round(clamped * 100) / 100;
  }

  return {
    v: 1,
    theme: pickId(input, 'theme'),
    color,
    pattern: pickId(input, 'pattern'),
    shape: pickId(input, 'shape'),
    emblem: pickId(input, 'emblem'),
    motion: pickId(input, 'motion'),
    speed,
  };
};

/**
 * Resolution order for a staked flag:
 *   1. the style the traveller picked for this flag,
 *   2. their saved signature,
 *   3. the product default.
 *
 * A corrupt stored signature must not block a flag drop, so a stored value that
 * fails validation degrades to the product default instead of throwing.
 */
const resolveFlagStyle = ({ provided, signature } = {}) => {
  if (provided !== undefined && provided !== null) {
    return normalizeFlagStyle(provided);
  }
  if (signature !== undefined && signature !== null) {
    try {
      return normalizeFlagStyle(signature);
    } catch (_) {
      return { ...DEFAULT_FLAG_STYLE };
    }
  }
  return { ...DEFAULT_FLAG_STYLE };
};

module.exports = {
  FLAG_STYLE_IDS,
  DEFAULT_FLAG_STYLE,
  normalizeFlagStyle,
  resolveFlagStyle,
};
