module.exports = [
  'strapi::logger',
  'strapi::errors',
  'strapi::security',
  'strapi::cors',
  'strapi::poweredBy',
  'strapi::query',
  ['strapi::body', { includeUnparsed: true }],
  'strapi::session',
  'strapi::favicon',
  'strapi::public',
];
