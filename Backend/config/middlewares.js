'use strict';

module.exports = ({ env }) => {
  const corsOrigins = env('CORS_ORIGINS', '')
    .split(',')
    .map((origin) => origin.trim())
    .filter(Boolean);

  if (corsOrigins.includes('*')) {
    throw new Error('CORS_ORIGINS must contain explicit origins and cannot include *');
  }

  return [
    'strapi::logger',
    'strapi::errors',
    'strapi::security',
    { name: 'strapi::cors', config: { origin: corsOrigins } },
    'strapi::poweredBy',
    {
      name: 'global::rate-limit',
      config: {
        defaults: {
          windowMs: env.int('RATE_LIMIT_WINDOW_MS', 60000),
          max: env.int('RATE_LIMIT_MAX', 300),
        },
        auth: {
          windowMs: env.int('AUTH_RATE_LIMIT_WINDOW_MS', 900000),
          max: env.int('AUTH_RATE_LIMIT_MAX', 10),
        },
        payment: {
          windowMs: env.int('PAYMENT_RATE_LIMIT_WINDOW_MS', 60000),
          max: env.int('PAYMENT_RATE_LIMIT_MAX', 30),
        },
        webhook: {
          windowMs: env.int('WEBHOOK_RATE_LIMIT_WINDOW_MS', 60000),
          max: env.int('WEBHOOK_RATE_LIMIT_MAX', 120),
        },
        ai: {
          windowMs: env.int('AI_RATE_LIMIT_WINDOW_MS', 60000),
          max: env.int('AI_RATE_LIMIT_MAX', 10),
        },
      },
    },
    'strapi::query',
    { name: 'strapi::body', config: { includeUnparsed: true } },
    'strapi::session',
    'strapi::favicon',
    'strapi::public',
  ];
};
