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

test('a cancelled reservation releases its slot for another player to rebook', async () => {
  const slot = { id: 21, isActive: true, reservation: null, day_plan: { dayType: 'workday' } };
  const reservations = new Map();
  let nextId = 0;

  const strapi = {
    db: {
      async transaction(callback) {
        const trx = (table) => ({
          where: (criteria) => ({
            forUpdate: () => ({
              first: async () => {
                assert.equal(table, 'time_slots');
                return criteria.id === slot.id ? { id: slot.id } : null;
              },
            }),
          }),
        });
        return callback({ trx });
      },
    },
    entityService: {
      async findOne(uid, id) {
        if (uid === 'api::time-slot.time-slot') {
          assert.equal(id, slot.id);
          return {
            ...slot,
            reservation: slot.reservation ? { ...slot.reservation } : null,
          };
        }
        assert.equal(uid, 'api::reservation.reservation');
        const reservation = reservations.get(id);
        return reservation
          ? { ...reservation, time_slot: reservation.time_slot ? { ...reservation.time_slot } : null }
          : null;
      },
      async create(uid, { data }) {
        assert.equal(uid, 'api::reservation.reservation');
        const reservation = {
          id: ++nextId,
          ...data,
          time_slot: { id: slot.id },
        };
        reservations.set(reservation.id, reservation);
        slot.reservation = reservation;
        return reservation;
      },
      async update(uid, id, { data }) {
        if (uid === 'api::reservation.reservation') {
          const reservation = reservations.get(id);
          Object.assign(reservation, data);
          if (data.time_slot === null) {
            slot.reservation = null;
            reservation.time_slot = null;
          }
          return { ...reservation };
        }
        assert.equal(uid, 'api::time-slot.time-slot');
        assert.equal(id, slot.id);
        Object.assign(slot, data);
        return slot;
      },
    },
  };
  const service = createReservationService({ strapi });
  const first = await service.createForAvailableSlot(slot.id, {
    player: 100,
    booking_status: 'pending',
  });

  await service.releaseReservationSlot(first.id, { booking_status: 'cancelled' });
  assert.equal(first.time_slot, null);
  assert.equal(reservations.get(first.id).time_slot, null);
  assert.equal(slot.isActive, true);

  const second = await service.createForAvailableSlot(slot.id, {
    player: 200,
    booking_status: 'pending',
  });
  assert.notEqual(second.id, first.id);
  assert.equal(second.player, 200);
  assert.equal(second.time_slot.id, slot.id);
  assert.equal(reservations.size, 2);
  assert.equal(slot.isActive, false);
  assert.equal(slot.reservation.id, second.id);
});
