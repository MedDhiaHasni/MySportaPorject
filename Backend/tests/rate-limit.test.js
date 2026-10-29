'use strict';

const assert = require('node:assert/strict');
const test = require('node:test');
const rateLimit = require('../src/middlewares/rate-limit');

function request(middleware, path, ip = '192.0.2.1') {
  const headers = {};
  const ctx = {
    path,
    ip,
    request: { ip },
    set(name, value) {
      headers[name] = value;
    },
  };
  return middleware(ctx, async () => {
    ctx.status = 200;
    ctx.body = { success: true };
  }).then(() => ({ ctx, headers }));
}

test('login, recovery, payment, and AI routes use their configured strict limits', async () => {
  const middleware = rateLimit({
    defaults: { windowMs: 60000, max: 20 },
    auth: { windowMs: 60000, max: 1 },
    payment: { windowMs: 60000, max: 1 },
    webhook: { windowMs: 60000, max: 3 },
    ai: { windowMs: 60000, max: 1 },
  });

  const paths = [
    '/api/auth/login',
    '/api/auth/forgot',
    '/api/auth/reset',
    '/api/payments/create-intent',
    '/api/ai-agent/chat',
  ];
  for (const [index, path] of paths.entries()) {
    const ip = `192.0.2.${index + 1}`;
    assert.equal((await request(middleware, path, ip)).ctx.status, 200);
    const limited = await request(middleware, path, ip);
    assert.equal(limited.ctx.status, 429);
    assert.equal(limited.ctx.body.error.status, 429);
    assert.equal(limited.headers['Retry-After'], '60');
  }
});

test('ordinary routes and Stripe webhooks use their separately configured limits', async () => {
  const middleware = rateLimit({
    defaults: { windowMs: 60000, max: 2 },
    webhook: { windowMs: 60000, max: 2 },
  });

  assert.equal((await request(middleware, '/api/courts')).ctx.status, 200);
  assert.equal((await request(middleware, '/api/courts')).ctx.status, 200);
  assert.equal((await request(middleware, '/api/courts')).ctx.status, 429);

  assert.equal((await request(middleware, '/api/payments/webhook')).ctx.status, 200);
  assert.equal((await request(middleware, '/api/payments/webhook')).ctx.status, 200);
  assert.equal((await request(middleware, '/api/payments/webhook')).ctx.status, 429);
});
