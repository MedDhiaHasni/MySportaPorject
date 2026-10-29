'use strict';

const assert = require('node:assert/strict');
const test = require('node:test');
const Module = require('node:module');

const originalLoad = Module._load;
Module._load = function (request, parent, isMain) {
  if (request === '@strapi/strapi') {
    return {
      factories: {
        createCoreService: (_uid, factory) => factory,
      },
    };
  }
  return originalLoad.call(this, request, parent, isMain);
};

const createReservationService = require('../src/api/reservation/services/reservation');
Module._load = originalLoad;

test('concurrent requests can claim a time slot only once', async () => {
  const slot = { id: 17, isActive: true, reservation: null, day_plan: { dayType: 'workday' } };
  const reservations = [];
  let lockTail = Promise.resolve();

  const strapi = {
    db: {
      async transaction(callback) {
        let releaseLock;
        try {
          return await callback({
            trx: (table) => ({
              where: () => ({
                forUpdate: () => ({
                  first: async () => {
                    assert.equal(table, 'time_slots');
                    const previous = lockTail;
                    lockTail = new Promise((resolve) => {
                      releaseLock = resolve;
                    });
                    await previous;
                    return { id: slot.id };
                  },
                }),
              }),
            }),
          });
        } finally {
          releaseLock?.();
        }
      },
    },
    entityService: {
      async findOne(uid, id) {
        assert.equal(uid, 'api::time-slot.time-slot');
        assert.equal(id, slot.id);
        return { ...slot };
      },
      async create(uid, { data }) {
        assert.equal(uid, 'api::reservation.reservation');
        const reservation = { id: reservations.length + 1, ...data };
        reservations.push(reservation);
        slot.reservation = reservation;
        return reservation;
      },
      async update(uid, id, { data }) {
        assert.equal(uid, 'api::time-slot.time-slot');
        assert.equal(id, slot.id);
        Object.assign(slot, data);
        return slot;
      },
    },
  };
  const service = createReservationService({ strapi });
  const reservationData = { player: 4, booking_status: 'pending' };

  const outcomes = await Promise.allSettled([
    service.createForAvailableSlot(slot.id, reservationData),
    service.createForAvailableSlot(slot.id, reservationData),
  ]);

  assert.equal(outcomes.filter((result) => result.status === 'fulfilled').length, 1);
  assert.equal(outcomes.filter((result) => result.status === 'rejected').length, 1);
  assert.match(
    outcomes.find((result) => result.status === 'rejected').reason.message,
    /not available/,
  );
  assert.equal(reservations.length, 1);
  assert.equal(slot.isActive, false);
  assert.equal(slot.reservation.id, reservations[0].id);
});
