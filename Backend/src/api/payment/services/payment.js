// @ts-nocheck
'use strict';

const Stripe = require('stripe');

module.exports = ({ strapi }) => ({

  // ─────────────────────────────────────────────────────────────────────────
  // Get Stripe instance
  // ─────────────────────────────────────────────────────────────────────────
  getStripe() {
    const key = process.env.STRIPE_SECRET_KEY;
    if (!key) throw new Error('STRIPE_SECRET_KEY is not set in .env');
    return Stripe(key);
  },

  async handleStripeEvent(event) {
    const object = event.data?.object;

    if (event.type === 'payment_intent.succeeded') {
      const payment = await this.getPaymentByIntentId(object.id);
      if (!payment) throw new Error('Payment record for Stripe intent was not found');
      if (object.currency !== 'eur' ||
          object.amount_received !== Math.round(Number(payment.amount) * 100)) {
        throw new Error('Stripe payment amount or currency does not match the payment record');
      }
      if (payment.status === 'refunded') return;

      const reservation = await strapi.entityService.findOne(
        'api::reservation.reservation',
        payment.reservation?.id,
      );
      if (!reservation) throw new Error('Reservation for Stripe payment was not found');

      if (payment.status !== 'succeeded') {
        await strapi.entityService.update('api::payment.payment', payment.id, {
          data: { status: 'succeeded' },
        });
      }

      if (['cancelled', 'cancel_requested', 'rejected'].includes(reservation.booking_status)) {
        await this.refundReservation(reservation.id);
      } else if (reservation.booking_status === 'pending') {
        await strapi.entityService.update(
          'api::reservation.reservation',
          reservation.id,
          { data: { booking_status: 'confirmed', payment_method: 'pay_now' } },
        );
      }
      return;
    }

    if (event.type === 'payment_intent.payment_failed') {
      const payment = await this.getPaymentByIntentId(object.id);
      if (!payment) throw new Error('Payment record for Stripe intent was not found');
      if (payment.status === 'pending') {
        await strapi.entityService.update('api::payment.payment', payment.id, {
          data: { status: 'failed' },
        });
      }
      return;
    }

    if (event.type === 'charge.refunded' && object.amount_refunded >= object.amount) {
      const intentId = typeof object.payment_intent === 'string'
        ? object.payment_intent
        : object.payment_intent?.id;
      if (!intentId) throw new Error('Refund event is missing its PaymentIntent reference');

      const payment = await this.getPaymentByIntentId(intentId);
      if (!payment) throw new Error('Payment record for Stripe refund was not found');
      if (payment.status !== 'refunded') {
        await strapi.entityService.update('api::payment.payment', payment.id, {
          data: { status: 'refunded' },
        });
      }
    }
  },

  async refundReservation(reservationId) {
    const payments = await this.getAllPaymentsByReservation(reservationId);
    const successfulPayments = payments.filter(
      (payment) => payment.status === 'succeeded' && payment.stripe_payment_intent_id,
    );
    if (!successfulPayments.length) return { status: 'not_paid' };

    const stripe = this.getStripe();
    const results = [];
    for (const payment of successfulPayments) {
      const refund = await stripe.refunds.create(
        { payment_intent: payment.stripe_payment_intent_id },
        { idempotencyKey: `sporta-payment-${payment.id}-refund` },
      );

      if (refund.status === 'succeeded' && payment.status !== 'refunded') {
        await strapi.entityService.update('api::payment.payment', payment.id, {
          data: { status: 'refunded' },
        });
      }
      results.push({ paymentId: payment.id, status: refund.status });
    }

    return { status: results.every((result) => result.status === 'succeeded') ? 'refunded' : 'pending' };
  },

  // ─────────────────────────────────────────────────────────────────────────
  // Get payment by ID with optional populate
  // ─────────────────────────────────────────────────────────────────────────
  async getPaymentById(id, populate = ['reservation']) {
    return await strapi.entityService.findOne('api::payment.payment', id, {
      populate: populate,
    });
  },

  // ─────────────────────────────────────────────────────────────────────────
  // Get payment by Stripe PaymentIntent ID
  // ─────────────────────────────────────────────────────────────────────────
  async getPaymentByIntentId(paymentIntentId) {
    return await strapi.db.query('api::payment.payment').findOne({
      where: { stripe_payment_intent_id: paymentIntentId },
      populate: { reservation: true },
    });
  },

  // ─────────────────────────────────────────────────────────────────────────
  // Get payment by reservation ID (latest)
  // ─────────────────────────────────────────────────────────────────────────
  async getPaymentByReservation(reservationId) {
    const payments = await strapi.db.query('api::payment.payment').findMany({
      where: { reservation: { id: reservationId } },
      orderBy: { createdAt: 'desc' },
      limit: 1,
    });
    
    return payments && payments.length > 0 ? payments[0] : null;
  },

  // ─────────────────────────────────────────────────────────────────────────
  // Get all payments for a reservation
  // ─────────────────────────────────────────────────────────────────────────
  async getAllPaymentsByReservation(reservationId) {
    return await strapi.db.query('api::payment.payment').findMany({
      where: { reservation: { id: reservationId } },
      orderBy: { createdAt: 'desc' },
    });
  },

  // ─────────────────────────────────────────────────────────────────────────
  // Create payment record in database
  // ─────────────────────────────────────────────────────────────────────────
  async createPaymentRecord(data) {
    return await strapi.entityService.create('api::payment.payment', {
      data: {
        amount: data.amount,
        currency: data.currency,
        status: data.status || 'pending',
        stripe_payment_intent_id: data.paymentIntentId,
        reservation: data.reservationId,
        payment_method_type: data.paymentMethodType || 'card',
        metadata: data.metadata || {},
      },
    });
  },

  // ─────────────────────────────────────────────────────────────────────────
  // Update payment status
  // ─────────────────────────────────────────────────────────────────────────
  async updatePaymentStatus(paymentId, status, additionalData = {}) {
    if (status === 'succeeded' || status === 'refunded') {
      throw new Error('Successful and refunded payment states are managed by Stripe events');
    }

    return await strapi.entityService.update('api::payment.payment', paymentId, {
      data: {
        status: status,
        ...additionalData,
      },
    });
  },

  // ─────────────────────────────────────────────────────────────────────────
  // Verify if payment is already succeeded for a reservation
  // ─────────────────────────────────────────────────────────────────────────
  async hasSuccessfulPayment(reservationId) {
    const payment = await this.getPaymentByReservation(reservationId);
    return payment && payment.status === 'succeeded';
  },

  // ─────────────────────────────────────────────────────────────────────────
  // Get all user payments (player)
  // ─────────────────────────────────────────────────────────────────────────
  async getUserPayments(playerId, limit = 50, offset = 0) {
    return await strapi.db.query('api::payment.payment').findMany({
      where: {
        reservation: {
          player: { id: playerId }
        }
      },
      populate: { reservation: { populate: ['court', 'court.venue'] } },
      orderBy: { createdAt: 'desc' },
      limit: limit,
      offset: offset,
    });
  },

  // ─────────────────────────────────────────────────────────────────────────
  // Get payment statistics for a player
  // ─────────────────────────────────────────────────────────────────────────
  async getPlayerPaymentStats(playerId) {
    const payments = await strapi.db.query('api::payment.payment').findMany({
      where: {
        reservation: {
          player: { id: playerId }
        },
        status: 'succeeded',
      },
    });

    const totalSpent = payments.reduce((sum, p) => sum + p.amount, 0);
    const totalPayments = payments.length;

    return {
      totalSpent,
      totalPayments,
      averageAmount: totalPayments > 0 ? totalSpent / totalPayments : 0,
    };
  },

  // ─────────────────────────────────────────────────────────────────────────
  // Get payment analytics for admin (date range)
  // ─────────────────────────────────────────────────────────────────────────
  async getPaymentAnalytics(startDate, endDate) {
    const payments = await strapi.db.query('api::payment.payment').findMany({
      where: {
        createdAt: {
          $gte: startDate,
          $lte: endDate,
        },
        status: 'succeeded',
      },
      populate: { reservation: { populate: ['court', 'court.venue'] } },
    });

    const totalAmount = payments.reduce((sum, p) => sum + p.amount, 0);
    const totalCount = payments.length;

    // Group by venue
    const byVenue = {};
    payments.forEach(payment => {
      const venueName = payment.reservation?.court?.venue?.name || 'Unknown';
      if (!byVenue[venueName]) {
        byVenue[venueName] = { count: 0, total: 0 };
      }
      byVenue[venueName].count++;
      byVenue[venueName].total += payment.amount;
    });

    return {
      totalAmount,
      totalCount,
      averageAmount: totalCount > 0 ? totalAmount / totalCount : 0,
      byVenue,
      payments,
    };
  },

  // ─────────────────────────────────────────────────────────────────────────
  // Get daily payment summary for dashboard
  // ─────────────────────────────────────────────────────────────────────────
  async getDailyPaymentSummary(days = 7) {
    const startDate = new Date();
    startDate.setDate(startDate.getDate() - days);
    startDate.setHours(0, 0, 0, 0);

    const payments = await strapi.db.query('api::payment.payment').findMany({
      where: {
        createdAt: {
          $gte: startDate.toISOString(),
        },
        status: 'succeeded',
      },
    });

    const daily = {};
    payments.forEach(payment => {
      const date = new Date(payment.createdAt).toISOString().split('T')[0];
      if (!daily[date]) {
        daily[date] = { count: 0, total: 0 };
      }
      daily[date].count++;
      daily[date].total += payment.amount;
    });

    return daily;
  },

  // ─────────────────────────────────────────────────────────────────────────
  // Check if payment can be refunded (within 30 days)
  // ─────────────────────────────────────────────────────────────────────────
  canRefund(payment) {
    if (!payment || payment.status !== 'succeeded') return false;
    
    const paymentDate = new Date(payment.createdAt);
    const now = new Date();
    const daysSincePayment = (now - paymentDate) / (1000 * 60 * 60 * 24);
    
    // Stripe allows refunds within 30 days (configurable)
    return daysSincePayment <= 30;
  },

  // ─────────────────────────────────────────────────────────────────────────
  // Cancel pending payment (if not yet succeeded)
  // ─────────────────────────────────────────────────────────────────────────
  async cancelPendingPayment(paymentId) {
    const payment = await this.getPaymentById(paymentId);
    
    if (!payment) throw new Error('Payment not found');
    if (payment.status !== 'pending') {
      throw new Error(`Cannot cancel payment with status: ${payment.status}`);
    }
    
    return await this.updatePaymentStatus(paymentId, 'cancelled');
  },

  // ─────────────────────────────────────────────────────────────────────────
  // Clean up old pending payments (older than 1 hour)
  // ─────────────────────────────────────────────────────────────────────────
  async cleanupStalePendingPayments() {
    const oneHourAgo = new Date();
    oneHourAgo.setHours(oneHourAgo.getHours() - 1);
    
    const stalePayments = await strapi.db.query('api::payment.payment').findMany({
      where: {
        status: 'pending',
        createdAt: {
          $lt: oneHourAgo.toISOString(),
        },
      },
    });
    
    let cleanedCount = 0;
    for (const payment of stalePayments) {
      await this.updatePaymentStatus(payment.id, 'cancelled');
      cleanedCount++;
    }
    
    return { cleanedCount };
  },
});