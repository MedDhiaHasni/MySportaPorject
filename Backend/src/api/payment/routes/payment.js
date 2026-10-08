// src/api/payment/routes/payment.js
'use strict';

module.exports = {
  routes: [
    {
      method: 'POST',
      path: '/payments/create-intent',
      handler: 'payment.createIntent',
      config: { auth: false, policies: ['global::authMiddleware'] },
    },
    {
      method: 'POST',
      path: '/payments/:id/confirm',
      handler: 'payment.confirmPayment',
      config: { auth: false, policies: ['global::authMiddleware'] },
    },
    
    {
      method: 'GET',
      path: '/payments',
      handler: 'payment.findAll',
      config: {
        auth: false,
        policies: ['global::authMiddleware', 'global::isManager'],
      },
    },
    {
      method: 'GET',
      path: '/payments/reservation/:reservationId',
      handler: 'payment.getByReservation',
      config: { auth: false, policies: ['global::authMiddleware'] },
    },
  ],
};