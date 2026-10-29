'use strict';

const MAX_BUCKETS = 20000;

function classifyRoute(path) {
  const route = path.replace(/\/+$/, '') || '/';

  if (/^\/(?:api\/)?auth\/(?:login|forgot|reset)$/.test(route)) return 'auth';
  if (/^\/(?:api\/)?payments\/webhook$/.test(route)) return 'webhook';
  if (/^\/(?:api\/)?payments(?:\/|$)/.test(route)) return 'payment';
  if (/^\/(?:api\/)?ai-agent(?:\/|$)/.test(route)) return 'ai';
  return 'defaults';
}

function removeExpiredBuckets(buckets, now) {
  for (const [key, bucket] of buckets) {
    if (bucket.resetAt <= now) buckets.delete(key);
  }
}

module.exports = (config = {}) => {
  const limits = {
    defaults: config.defaults || { windowMs: 60000, max: 300 },
    auth: config.auth || { windowMs: 900000, max: 10 },
    payment: config.payment || { windowMs: 60000, max: 30 },
    webhook: config.webhook || { windowMs: 60000, max: 120 },
    ai: config.ai || { windowMs: 60000, max: 10 },
  };
  const buckets = new Map();
  let requestCount = 0;

  return async (ctx, next) => {
    const category = classifyRoute(ctx.path);
    const policy = limits[category];
    const now = Date.now();
    const ip = ctx.ip || ctx.request.ip || 'unknown';
    const key = `${category}:${ip}`;
    let bucket = buckets.get(key);

    if (!bucket || bucket.resetAt <= now) {
      if (++requestCount % 256 === 0 || buckets.size >= MAX_BUCKETS) {
        removeExpiredBuckets(buckets, now);
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

      bucket = { count: 0, resetAt: now + policy.windowMs };
      buckets.set(key, bucket);
    }

    bucket.count += 1;
    ctx.set('X-RateLimit-Limit', String(policy.max));
    ctx.set('X-RateLimit-Remaining', String(Math.max(0, policy.max - bucket.count)));
    ctx.set('X-RateLimit-Reset', String(Math.ceil(bucket.resetAt / 1000)));

    if (bucket.count > policy.max) {
      ctx.set('Retry-After', String(Math.max(1, Math.ceil((bucket.resetAt - now) / 1000))));
      ctx.status = 429;
      ctx.body = {
        error: {
          status: 429,
          name: 'TooManyRequestsError',
          message: 'Too many requests. Please try again later.',
        },
      };
      return;
    }

    await next();
  };
};
