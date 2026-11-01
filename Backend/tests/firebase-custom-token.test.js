'use strict';

const assert = require('node:assert/strict');
const test = require('node:test');

const authService = require('../src/api/auth/services/auth');
const firebaseService = require('../src/firebase/firebase.service');
const originalCreateCustomToken = firebaseService.createCustomToken;
const issuedTokens = [];
firebaseService.createCustomToken = async (uid, claims) => {
  issuedTokens.push({ uid, claims });
  return 'test-custom-token';
};

function installStrapiUser(user, profile) {
  global.strapi = {
    db: {
      query(uid) {
        return {
          async findOne({ where }) {
            if (uid === 'plugin::users-permissions.user') {
              assert.equal(where.id, user.id);
              return user;
            }
            assert.equal(uid, `api::${user.user_role}.${user.user_role}`);
            assert.deepEqual(where, { [user.user_role]: user.id });
            return profile;
          },
        };
      },
    },
  };
}

test('issues a role-claimed token using the linked profile UID', async () => {
  const user = { id: 14, user_role: 'player' };
  installStrapiUser(user, { id: 9, firebaseUid: 'sporta_player_14' });

  const result = await authService.createFirebaseCustomToken(user.id);

  assert.deepEqual(result, {
    customToken: 'test-custom-token',
    firebaseUid: 'sporta_player_14',
  });
  assert.deepEqual(issuedTokens.at(-1), {
    uid: 'sporta_player_14',
    claims: { role: 'player', strapiUserId: '14' },
  });
});

test('uses the existing backend fallback UID when a worker has no stored UID', async () => {
  const user = { id: 27, user_role: 'worker' };
  installStrapiUser(user, { id: 12, firebaseUid: null });

  const result = await authService.createFirebaseCustomToken(user.id);

  assert.equal(result.firebaseUid, 'sporta_worker_27');
  assert.equal(issuedTokens.at(-1).claims.role, 'worker');
});

test('does not issue a token for unsupported roles', async () => {
  installStrapiUser({ id: 42, user_role: 'unknown' }, null);

  await assert.rejects(
    authService.createFirebaseCustomToken(42),
    (error) => error.status === 403,
  );
});

test.after(() => {
  firebaseService.createCustomToken = originalCreateCustomToken;
  delete global.strapi;
});
