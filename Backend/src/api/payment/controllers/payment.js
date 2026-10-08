// src/api/payment/controllers/payment.js
// @ts-nocheck
'use strict';

const Stripe = require('stripe');

// ── NOTE ON CURRENCY ──────────────────────────────────────────────────────────
// Stripe does NOT support TND (Tunisian Dinar).
// We charge in EUR but treat 1 EUR = 1 DT for simplicity.
// The amount stored in the DB and shown to the user is always in DT.
// Stripe processes it as EUR cents (e.g. 50 DT → 5000 EUR cents).
// ─────────────────────────────────────────────────────────────────────────────
const DISPLAY_CURRENCY = 'DT';    // shown to user
const STRIPE_CURRENCY  = 'eur';   // what Stripe actually processes

function getStripe() {
  const key = process.env.STRIPE_SECRET_KEY;
  if (!key) throw new Error('STRIPE_SECRET_KEY is not set in .env');
  return Stripe(key);
}

module.exports = {

  // ── POST /payments/create-intent ─────────────────────────────────────────
  async createIntent(ctx) {
    try {
      const user = ctx.state.user;
      if (!user) return ctx.unauthorized('Authentication required');

      const { reservationId } = ctx.request.body;
      if (!reservationId) return ctx.badRequest('reservationId is required');

      const reservation = await strapi.entityService.findOne(
        'api::reservation.reservation', reservationId,
        { populate: ['player', 'court', 'court.venue', 'payments'] },
      );
      if (!reservation) return ctx.notFound('Reservation not found');

      const playerProfile = await strapi.db.query('api::player.player').findOne({ where: { player: user.id } });
      if (!playerProfile || reservation.player?.id !== playerProfile.id) {
        return ctx.forbidden('This reservation does not belong to you');
      }
      if (reservation.booking_status === 'confirmed') return ctx.badRequest('Already paid and confirmed');
      if (reservation.booking_status === 'cancelled')  return ctx.badRequest('Cannot pay for a cancelled reservation');

      const existingSucceeded = (reservation.payments || []).find(p => p.status === 'succeeded');
      if (existingSucceeded) return ctx.badRequest('A successful payment already exists for this reservation');

      const stripe = getStripe();

      // Treat 1 DT = 1 EUR for Stripe processing
      // Stripe requires amounts in the smallest currency unit (cents)
      const amountCents = Math.round(reservation.total_price * 100);

      const paymentIntent = await stripe.paymentIntents.create({
        amount:   amountCents,
        currency: STRIPE_CURRENCY,
        metadata: {
          reservation_id:   String(reservationId),
          player_id:        String(playerProfile.id),
          court_name:       reservation.court?.name ?? '',
          venue_name:       reservation.court?.venue?.name ?? '',
          display_currency: DISPLAY_CURRENCY,
          display_amount:   String(reservation.total_price),
        },
        automatic_payment_methods: { enabled: true },
        // Pre-fill billing address country to Tunisia
        payment_method_options: {
          card: {
            mandate_options: undefined,
          },
        },
      });

      const payment = await strapi.entityService.create('api::payment.payment', {
        data: {
          amount:                   reservation.total_price,
          currency:                 DISPLAY_CURRENCY,   // store as DT in our DB
          status:                   'pending',
          stripe_payment_intent_id: paymentIntent.id,
          reservation:              reservationId,
        },
      });

      return ctx.send({
        success:         true,
        clientSecret:    paymentIntent.client_secret,
        paymentId:       payment.id,
        paymentIntentId: paymentIntent.id,
        amount:          reservation.total_price,
        currency:        DISPLAY_CURRENCY,
        publishableKey:  process.env.STRIPE_PUBLISHABLE_KEY,
      });
    } catch (error) {
      strapi.log.error('[Payment] createIntent error:', error.message);
      if (error.type === 'StripeInvalidRequestError') return ctx.badRequest(`Stripe error: ${error.message}`);
      return ctx.badRequest(error.message);
    }
  },

  // ── POST /payments/:id/confirm ────────────────────────────────────────────
  async confirmPayment(ctx) {
    try {
      const { id } = ctx.params;
      const user   = ctx.state.user;
      if (!user) return ctx.unauthorized('Authentication required');

      const payment = await strapi.entityService.findOne(
        'api::payment.payment', id,
        { populate: ['reservation', 'reservation.player', 'reservation.time_slot'] },
      );
      if (!payment) return ctx.notFound('Payment record not found');

      const playerProfile = await strapi.db.query('api::player.player').findOne({ where: { player: user.id } });
      if (!playerProfile || payment.reservation?.player?.id !== playerProfile.id) {
        return ctx.forbidden('This payment does not belong to you');
      }
      if (payment.status === 'succeeded') {
        return ctx.send({ success: true, status: 'succeeded', message: 'Payment already confirmed' });
      }

      const stripe        = getStripe();
      const paymentIntent = await stripe.paymentIntents.retrieve(payment.stripe_payment_intent_id);

      if (paymentIntent.status === 'succeeded') {
        await strapi.entityService.update('api::payment.payment', id, { data: { status: 'succeeded' } });
        await strapi.entityService.update('api::reservation.reservation', payment.reservation.id, {
          data: { booking_status: 'confirmed', payment_method: 'pay_now' },
        });
        return ctx.send({
          success:       true,
          status:        'succeeded',
          paymentId:     id,
          reservationId: payment.reservation.id,
          message:       'Payment successful! Reservation confirmed.',
        });
      } else if (['requires_payment_method', 'canceled'].includes(paymentIntent.status)) {
        await strapi.entityService.update('api::payment.payment', id, { data: { status: 'failed' } });
        return ctx.send({ success: false, status: 'failed', message: 'Payment failed or was cancelled.' });
      } else {
        return ctx.send({ success: false, status: paymentIntent.status, message: `Payment status: ${paymentIntent.status}` });
      }
    } catch (error) {
      strapi.log.error('[Payment] confirmPayment error:', error.message);
      if (error.type === 'StripeInvalidRequestError') return ctx.badRequest(`Stripe error: ${error.message}`);
      return ctx.badRequest(error.message);
    }
  },

  // ── GET /payments/reservation/:reservationId ──────────────────────────────
  async getByReservation(ctx) {
    try {
      const { reservationId } = ctx.params;
      const user              = ctx.state.user;
      if (!user) return ctx.unauthorized('Authentication required');

      const payments = await strapi.db.query('api::payment.payment').findMany({
        where:   { reservation: { id: reservationId } },
        orderBy: { createdAt: 'desc' },
        limit:   1,
      });
      if (!payments || payments.length === 0) return ctx.notFound('No payment found for this reservation');
      return ctx.send({ payment: payments[0] });
    } catch (error) {
      strapi.log.error('[Payment] getByReservation error:', error.message);
      return ctx.badRequest(error.message);
    }
  },

  // ── GET /payments ─────────────────────────────────────────────────────────
  async findAll(ctx) {
    try {
      const user = ctx.state.user;
      if (!user) return ctx.unauthorized('Authentication required');
      if (!['manager', 'admin'].includes(user.user_role)) {
        return ctx.forbidden('Only managers and admins can access payment records');
      }

      const { status, limit = 100, page = 1 } = ctx.query;
      const offset = (Number(page) - 1) * Number(limit);

      const paymentFilters = {};
      if (status && ['pending', 'succeeded', 'failed'].includes(status)) {
        paymentFilters.status = status;
      }

      if (user.user_role === 'manager') {
        const managerProfile = await strapi.db.query('api::manager.manager').findOne({
          where: { manager: user.id },
        });
        if (!managerProfile) return ctx.unauthorized('Manager profile not found');

        const venues = await strapi.entityService.findMany('api::venue.venue', {
          filters:  { manager: managerProfile.id },
          populate: { courts: true },
        });
        const courtIds = venues.flatMap(v => (v.courts || []).map(c => c.id));

        if (courtIds.length === 0) {
          return ctx.send({
            payments: [], total: 0,
            stats: { total: 0, totalRevenue: 0, pending: 0, succeeded: 0, failed: 0 },
          });
        }

        const reservations = await strapi.entityService.findMany('api::reservation.reservation', {
          filters: { court: { id: { $in: courtIds } } },
          fields:  ['id'],
          limit:   9999,
        });
        const reservationIds = reservations.map(r => r.id);

        if (reservationIds.length === 0) {
          return ctx.send({
            payments: [], total: 0,
            stats: { total: 0, totalRevenue: 0, pending: 0, succeeded: 0, failed: 0 },
          });
        }

        paymentFilters.reservation = { id: { $in: reservationIds } };
      }

      const [payments, total] = await Promise.all([
        strapi.entityService.findMany('api::payment.payment', {
          filters:  paymentFilters,
          populate: {
            reservation: {
              populate: {
                court:  { populate: ['court_img', 'venue'] },
                player: { populate: ['player'] },
              },
            },
          },
          sort:  { createdAt: 'desc' },
          limit: Number(limit),
          start: offset,
        }),
        strapi.db.query('api::payment.payment').count({ where: paymentFilters }),
      ]);

      const baseUrl  = strapi.config.get('server.url') || '';
      const enriched = payments.map(p => {
        const court = p.reservation?.court;
        if (court?.court_img?.url) {
          court.court_img_url = court.court_img.url.startsWith('http')
            ? court.court_img.url
            : `${baseUrl}${court.court_img.url}`;
        }
        return p;
      });

      const statsFilter = user.user_role === 'admin'
        ? {}
        : { reservation: paymentFilters.reservation };

      const allPayments = await strapi.entityService.findMany('api::payment.payment', {
        filters: statsFilter, fields: ['status', 'amount'], limit: 9999,
      });
      const stats = allPayments.reduce(
        (acc, p) => {
          acc.total++;
          acc[p.status] = (acc[p.status] || 0) + 1;
          if (p.status === 'succeeded') acc.totalRevenue += (p.amount || 0);
          return acc;
        },
        { total: 0, totalRevenue: 0, pending: 0, succeeded: 0, failed: 0 },
      );

      return ctx.send({ payments: enriched, total, page: Number(page), limit: Number(limit), stats });
    } catch (error) {
      strapi.log.error('[Payment] findAll error:', error.message);
      return ctx.badRequest(error.message);
    }
  },
};