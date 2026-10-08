// @ts-nocheck
'use strict';

// ─────────────────────────────────────────────────────────────────────────────
// Generate a unique booking reference  e.g.  BK-20250615-A3F9
// ─────────────────────────────────────────────────────────────────────────────
async function generateBookingReference() {
  const datePart   = new Date().toISOString().split('T')[0].replace(/-/g, ''); // 20250615
  const randomPart = Math.random().toString(36).substring(2, 6).toUpperCase(); // A3F9

  const reference = `BK-${datePart}-${randomPart}`;

  // Make sure it's unique in the DB
  const existing = await strapi.db.query('api::reservation.reservation').findOne({
    where: { booking_reference: reference },
  });

  // Recurse on collision (extremely rare)
  if (existing) {
    return generateBookingReference();
  }

  return reference;
}

module.exports = { generateBookingReference };