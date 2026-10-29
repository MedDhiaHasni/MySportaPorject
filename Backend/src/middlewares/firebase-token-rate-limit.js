'use strict';

const WINDOW_MS = 15 * 60 * 1000;
const MAX_REQUESTS = 10;
const MAX_BUCKETS = 20000;
const buckets = new Map();
let requestCount = 0;

function removeExpiredBuckets(now) {
  for (const [ip, bucket] of buckets) {
    if (bucket.resetAt <= now) buckets.delete(ip);
  }
}

module.exports = () => async (ctx, next) => {
  const now = Date.now();
  const ip = ctx.ip || ctx.request.ip || 'unknown';
  let bucket = buckets.get(ip);

  if (!bucket || bucket.resetAt <= now) {
    if (++requestCount % 256 === 0 || buckets.size >= MAX_BUCKETS) {
      removeExpiredBuckets(now);
    }

    if (buckets.size >= MAX_BUCKETS) {
      ctx.status = 503;
      ctx.body = {
        error: {
          status: 503,
          name: 'RateLimitUnavailableError',
          message: 'Request rate limiting is temporarily unavailable.',
        },
      };
      return;
    }

    bucket = { count: 0, resetAt: now + WINDOW_MS };
    buckets.set(ip, bucket);
  }

  bucket.count += 1;
  ctx.set('X-RateLimit-Limit', String(MAX_REQUESTS));
  ctx.set('X-RateLimit-Remaining', String(Math.max(0, MAX_REQUESTS - bucket.count)));
  ctx.set('X-RateLimit-Reset', String(Math.ceil(bucket.resetAt / 1000)));

  if (bucket.count > MAX_REQUESTS) {
    ctx.set('Retry-After', String(Math.max(1, Math.ceil((bucket.resetAt - now) / 1000))));
    ctx.status = 429;
    ctx.body = {
      error: {
        status: 429,
        name: 'TooManyRequestsError',
        message: 'Too many attempts, try again later',
      },
    };
    return;
  }

  await next();
};
