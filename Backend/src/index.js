// @ts-nocheck
'use strict';

module.exports = {
  /**
   * An asynchronous register function that runs before
   * your application is initialized.
   *
   * This gives you an opportunity to extend code.
   */
  register() {
    if (!process.env.JWT_SECRET?.trim()) {
      throw new Error('JWT_SECRET must be set before starting the backend');
    }
  },

  /**
   * An asynchronous bootstrap function that runs before
   * your application gets started.
   *
   * This gives you an opportunity to set up your data model,
   * run jobs, or perform some special logic.
   */
  async bootstrap({ strapi }) {
    await require('./utils/reservation-slot-constraint')
      .ensureReservationSlotUniqueIndex(strapi);

    if (!process.env.OPENROUTER_API_KEY) {
      strapi.log.warn('[ai-agent] OPENROUTER_API_KEY missing in .env');
    }

    const email = process.env.BOOTSTRAP_ADMIN_EMAIL?.trim();
    const username = process.env.BOOTSTRAP_ADMIN_USERNAME?.trim();
    const password = process.env.BOOTSTRAP_ADMIN_PASSWORD;
    const configuredValues = [email, username, password].filter(Boolean).length;

    if (configuredValues === 0) {
      strapi.log.info('[bootstrap] Admin account creation is disabled');
      return;
    }

    if (!email || !username || !password) {
      throw new Error(
        'BOOTSTRAP_ADMIN_EMAIL, BOOTSTRAP_ADMIN_USERNAME, and BOOTSTRAP_ADMIN_PASSWORD must all be set together',
      );
    }

    if (password.trim().length < 12) {
      throw new Error('BOOTSTRAP_ADMIN_PASSWORD must be at least 12 characters');
    }

    const existingAdmin = await strapi.db
      .query('plugin::users-permissions.user')
      .findOne({ where: { email } });
    if (existingAdmin) {
      strapi.log.info('[bootstrap] Configured admin account already exists');
      return;
    }

    const role = await strapi.db
      .query('plugin::users-permissions.role')
      .findOne({ where: { type: 'authenticated' } });
    if (!role) {
      throw new Error('Cannot create bootstrap admin: authenticated role was not found');
    }

    await strapi.plugins['users-permissions'].services.user.add({
      username,
      email,
      password,
      role: role.id,
      user_role: 'admin',
    });
    strapi.log.info('[bootstrap] Admin account created from environment configuration');
  },
};
