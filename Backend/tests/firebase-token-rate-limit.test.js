'use strict';

const assert = require('node:assert/strict');
const test = require('node:test');
const rateLimit = require('../src/middlewares/firebase-token-rate-limit');

test('limits Firebase custom-token requests to ten per IP per window', async () => {
  const middleware = rateLimit();
  const ip = '198.51.100.40';

  for (let attempt = 0; attempt < 10; attempt++) {
    const ctx = {
      ip,
      request: { ip },
      set() {},
    };
    let continued = false;
    await middleware(ctx, async () => {
      continued = true;
    });
    assert.equal(continued, true);
  }

  const headers = {};
  const limited = {
    ip,
    request: { ip },
    set(name, value) {
      headers[name] = value;
    },
  };
  let continued = false;
  await middleware(limited, async () => {
    continued = true;
  });

  assert.equal(continued, false);
  assert.equal(limited.status, 429);
  assert.equal(limited.body.error.message, 'Too many attempts, try again later');
  assert.equal(headers['X-RateLimit-Limit'], '10');
  assert.ok(Number(headers['Retry-After']) > 0);
});
