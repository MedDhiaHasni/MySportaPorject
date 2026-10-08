// src/api/auth/services/auth.js
// @ts-nocheck
const jwt    = require('jsonwebtoken');
const crypto = require('crypto');
const JWT_SECRET = process.env.JWT_SECRET || 'secret';

module.exports = {

    async registerUser({ username, email, password, phone }) {
        const existing = await strapi.db.query('plugin::users-permissions.user').findOne({ where: { email } });
        if (existing) throw new Error('User already exists');

        const role = await strapi.db.query('plugin::users-permissions.role').findOne({ where: { type: 'authenticated' } });

        const user = await strapi.plugins['users-permissions'].services.user.add({
            username, email, password, role: role.id, user_role: 'player',
        });

        try {
            await strapi.db.query('api::player.player').create({
                data: { phone: phone || null, player: user.id },
            });
        } catch (error) {
            console.error('Error creating player profile:', error.message);
        }
        return user;
    },

    async loginUser({ email, password }) {
        const user = await strapi.db.query('plugin::users-permissions.user').findOne({ where: { email } });
        if (!user) throw new Error('User not found');
        const valid = await strapi.plugins['users-permissions'].services.user.validatePassword(password, user.password);
        if (!valid) throw new Error('Invalid password');
        const token = jwt.sign({ id: user.id, user_role: user.user_role }, JWT_SECRET, { expiresIn: '7d' });
        return { token, user };
    },

    async resetPassword(token, password) {
        const user = await strapi.db.query('plugin::users-permissions.user').findOne({ where: { resetPasswordToken: token } });
        if (!user) throw new Error('Invalid or expired reset token');
        await strapi.plugins['users-permissions'].services.user.edit(user.id, { password });
        await strapi.db.query('plugin::users-permissions.user').update({
            where: { id: user.id },
            data:  { resetPasswordToken: null },
        });
    },

    async changePassword(userId, oldPassword, newPassword) {
        const user = await strapi.db.query('plugin::users-permissions.user').findOne({ where: { id: userId } });
        if (!user) throw new Error('User not found');
        const valid = strapi.plugins['users-permissions'].services.user.validatePassword(oldPassword, user.password);
        if (!valid) throw new Error('Invalid old password');
        await strapi.plugins['users-permissions'].services.user.edit(user.id, { password: newPassword });
    },

    // ── forgotPassword ────────────────────────────────────────────────────────
    // Generates a reset token, saves it to the user record, then emails a link
    // that points to the static HTML reset page served by Strapi at:
    //   GET /reset-password.html?token=TOKEN
    //
    // Set PUBLIC_URL in your .env to your Strapi server URL, e.g.:
    //   PUBLIC_URL=http://10.0.2.2:1337    (local Android dev)
    //   PUBLIC_URL=https://your-domain.com (production)
    async forgotPassword(email) {
        const { sendEmail } = require('../../../utils/email');

        const user = await strapi.db.query('plugin::users-permissions.user').findOne({ where: { email } });
        if (!user) throw new Error('No account found with that email address');

        // Generate a secure random token
        const token = crypto.randomBytes(32).toString('hex');

        // Save token to user record (expires in 1 hour — enforced by UI/backend)
        await strapi.db.query('plugin::users-permissions.user').update({
            where: { id: user.id },
            data:  { resetPasswordToken: token },
        });

        // n7adher el reset link
        const publicUrl  = (process.env.PUBLIC_URL || 'http://localhost:1337').replace(/\/$/, ''); // na7i hak el / fi le5er
        const resetLink  = `${publicUrl}/reset-password.html?token=${token}`;

        console.log(`[forgotPassword] Reset link for ${email}: ${resetLink}`);

        await sendEmail(
            email,
            'Sporta — Reset Your Password',
            _buildEmailHtml(user.username || 'Player', resetLink), // player wala worker wala manager
            _buildEmailText(user.username || 'Player', resetLink),
        );

        return { message: 'Password reset email sent' };
    },

    //  getMe hedhi mafihech el worker 5ater el auth el main mte3ha houwa player wel manager
    async getMe(userId) {
        const user = await strapi.db.query('plugin::users-permissions.user').findOne({
            where: { id: userId }, populate: ['role'],
        });
        if (!user) throw new Error('User not found');

        let profile = null;
        if (user.user_role === 'player') {
            profile = await strapi.db.query('api::player.player').findOne({
                where:   { player: userId },
                populate: { player: true, photo: true },
            });
        } else if (user.user_role === 'manager') {
            profile = await strapi.db.query('api::manager.manager').findOne({
                where:   { manager: userId },
                populate: { manager: true, photo: true },
            });
        }

        const baseUrl  = strapi.config.get('server.url') || '';
        const rawUrl   = profile?.photo?.url || null;
        const photoUrl = rawUrl
            ? (rawUrl.startsWith('http') ? rawUrl : `${baseUrl}${rawUrl}`)
            : null;

        return { user, profile, photoUrl };
    },

    async updateProfile(userId, { username, email, phone }) {
        const user = await strapi.db.query('plugin::users-permissions.user').findOne({ where: { id: userId } });
        if (!user) throw new Error('User not found');

        if (email && email !== user.email) {
            const existing = await strapi.db.query('plugin::users-permissions.user').findOne({ where: { email } });
            if (existing) throw new Error('Email already in use');
        }

        const updateUser = await strapi.db.query('plugin::users-permissions.user').update({
            where: { id: userId },
            data:  { username: username || user.username, email: email || user.email },
        });

        let updateProfile = null;
        if (user.user_role === 'player') {
            const profile = await strapi.db.query('api::player.player').findOne({ where: { player: userId } });
            if (profile && phone !== undefined) {
                updateProfile = await strapi.db.query('api::player.player').update({
                    where: { id: profile.id }, data: { phone: phone || profile.phone },
                });
            }
        } else if (user.user_role === 'manager') {
            const profile = await strapi.db.query('api::manager.manager').findOne({ where: { manager: userId } });
            if (profile && phone !== undefined) {
                updateProfile = await strapi.db.query('api::manager.manager').update({
                    where: { id: profile.id }, data: { phone: phone || profile.phone },
                });
            }
        }
        return { updateUser, updateProfile };
    },

    async updateFirebaseUid(userId, firebaseUid, fcmToken) {
        const user = await strapi.db.query('plugin::users-permissions.user').findOne({ where: { id: userId } });
        if (!user) throw new Error('User not found');

        const data = { firebaseUid };
        if (fcmToken && fcmToken.trim() !== '') data.fcmToken = fcmToken;

        let updatedProfile = null;
        if (user.user_role === 'player') {
            const profile = await strapi.db.query('api::player.player').findOne({ where: { player: userId } });
            if (!profile) throw new Error('Player profile not found');
            updatedProfile = await strapi.db.query('api::player.player').update({ where: { id: profile.id }, data });
        } else if (user.user_role === 'manager') {
            const profile = await strapi.db.query('api::manager.manager').findOne({ where: { manager: userId } });
            if (!profile) throw new Error('Manager profile not found');
            updatedProfile = await strapi.db.query('api::manager.manager').update({ where: { id: profile.id }, data });
        } else {
            throw new Error('Invalid user role');
        }

        return { firebaseUid, fcmToken: fcmToken || null, profile: updatedProfile };
    },

    async updateProfilePhoto(userId, fileId) {
        const user = await strapi.db.query('plugin::users-permissions.user').findOne({ where: { id: userId } });
        if (!user) throw new Error('User not found');

        if (user.user_role === 'player') {
            const profile = await strapi.db.query('api::player.player').findOne({ where: { player: userId } });
            if (!profile) throw new Error('Player profile not found');
            await strapi.db.query('api::player.player').update({ where: { id: profile.id }, data: { photo: fileId } });
        } else if (user.user_role === 'manager') {
            const profile = await strapi.db.query('api::manager.manager').findOne({ where: { manager: userId } });
            if (!profile) throw new Error('Manager profile not found');
            await strapi.db.query('api::manager.manager').update({ where: { id: profile.id }, data: { photo: fileId } });
        } else if (user.user_role === 'worker') {
            const profile = await strapi.db.query('api::worker.worker').findOne({ where: { worker: userId } });
            if (!profile) throw new Error('Worker profile not found');
            await strapi.db.query('api::worker.worker').update({ where: { id: profile.id }, data: { photo: fileId } });
        } else {
            throw new Error('Invalid user role');
        }
    },
};

// 
// template el email 
// 

function _buildEmailText(name, link) {
    return `Hi ${name},

We received a request to reset your Sporta password.

Click the link below to set a new password:
${link}

This link will expire in 1 hour.

If you didn't request a password reset, you can safely ignore this email — your password won't change.

— The Sporta Team`;
}

function _buildEmailHtml(name, link) {
    return `<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
  <title>Reset Your Password</title>
</head>
<body style="margin:0;padding:0;background:#f2f4f7;font-family:'Helvetica Neue',Helvetica,Arial,sans-serif;">
  <table width="100%" cellpadding="0" cellspacing="0" style="background:#f2f4f7;padding:40px 0;">
    <tr>
      <td align="center">
        <table width="520" cellpadding="0" cellspacing="0" style="background:#ffffff;border-radius:20px;overflow:hidden;box-shadow:0 4px 24px rgba(0,0,0,0.07);">
          <!-- Header -->
          <tr>
            <td style="background:#009999;padding:36px 40px;text-align:center;">
              <div style="font-size:28px;font-weight:900;color:#ffffff;letter-spacing:-0.5px;">⚽ Sporta</div>
              <div style="font-size:13px;color:rgba(255,255,255,0.75);margin-top:4px;">Sports Court Booking</div>
            </td>
          </tr>
          <!-- Body -->
          <tr>
            <td style="padding:40px 40px 32px;">
              <h1 style="margin:0 0 8px;font-size:22px;font-weight:800;color:#0a0e1a;letter-spacing:-0.3px;">Reset your password</h1>
              <p style="margin:0 0 24px;font-size:15px;color:#64748b;line-height:1.6;">Hi <strong style="color:#0a0e1a;">${name}</strong>, we received a request to reset the password for your Sporta account.</p>

              <p style="margin:0 0 28px;font-size:14px;color:#64748b;line-height:1.6;">Click the button below to choose a new password. This link expires in <strong>1 hour</strong>.</p>

              <!-- CTA Button -->
              <table cellpadding="0" cellspacing="0" style="margin:0 auto 32px;">
                <tr>
                  <td style="background:#009999;border-radius:14px;">
                    <a href="${link}" style="display:block;padding:16px 40px;font-size:15px;font-weight:700;color:#ffffff;text-decoration:none;letter-spacing:-0.2px;">
                      Reset My Password →
                    </a>
                  </td>
                </tr>
              </table>

              <!-- Fallback link -->
              <p style="margin:0 0 8px;font-size:12px;color:#94a3b8;">If the button doesn't work, copy and paste this link into your browser:</p>
              <p style="margin:0 0 32px;font-size:12px;word-break:break-all;">
                <a href="${link}" style="color:#009999;">${link}</a>
              </p>

              <hr style="border:none;border-top:1px solid #e8edf3;margin:0 0 24px;" />
              <p style="margin:0;font-size:12px;color:#b0b7c3;line-height:1.6;">If you didn't request a password reset, you can safely ignore this email. Your password will remain unchanged.</p>
            </td>
          </tr>
          <!-- Footer -->
          <tr>
            <td style="background:#f8fafc;padding:20px 40px;text-align:center;border-top:1px solid #e8edf3;">
              <p style="margin:0;font-size:12px;color:#b0b7c3;">© ${new Date().getFullYear()} Sporta. All rights reserved.</p>
            </td>
          </tr>
        </table>
      </td>
    </tr>
  </table>
</body>
</html>`;
}

































/*// src/api/auth/services/auth.js
// @ts-nocheck
const jwt    = require('jsonwebtoken');
const crypto = require('crypto');
const JWT_SECRET = process.env.JWT_SECRET || 'secret';

module.exports = {

    async registerUser({ username, email, password, phone }) {
        const existing = await strapi.db.query('plugin::users-permissions.user').findOne({ where: { email } });
        if (existing) throw new Error('User already exists');

        const role = await strapi.db.query('plugin::users-permissions.role').findOne({ where: { type: 'authenticated' } });

        const user = await strapi.plugins['users-permissions'].services.user.add({
            username, email, password, role: role.id, user_role: 'player',
        });
        console.log('User registered:', user.id);

        try {
            const profile = await strapi.db.query('api::player.player').create({
                data: { phone: phone || null, player: user.id },
            });
            console.log('Player profile created:', profile.id);
        } catch (error) {
            console.error('Error creating player profile:', error.message);
        }
        return user;
    },

    async loginUser({ email, password }) {
        const user = await strapi.db.query('plugin::users-permissions.user').findOne({ where: { email } });
        if (!user) throw new Error('User not found');
        const valid = await strapi.plugins['users-permissions'].services.user.validatePassword(password, user.password);
        if (!valid) throw new Error('Invalid password');
        const token = jwt.sign({ id: user.id, user_role: user.user_role }, JWT_SECRET, { expiresIn: '7d' });
        return { token, user };
    },

    async resetPassword(token, password) {
        const user = await strapi.db.query('plugin::users-permissions.user').findOne({ where: { resetPasswordToken: token } });
        if (!user) throw new Error('Invalid token');
        await strapi.plugins['users-permissions'].services.user.edit(user.id, { password });
        await strapi.db.query('plugin::users-permissions.user').update({ where: { id: user.id }, data: { resetPasswordToken: null } });
    },

    async changePassword(userId, oldPassword, newPassword) {
        const user = await strapi.db.query('plugin::users-permissions.user').findOne({ where: { id: userId } });
        if (!user) throw new Error('User not found');
        const valid = strapi.plugins['users-permissions'].services.user.validatePassword(oldPassword, user.password);
        if (!valid) throw new Error('Invalid old password');
        await strapi.plugins['users-permissions'].services.user.edit(user.id, { password: newPassword });
    },

    async forgotPassword(email) {
        const { sendEmail } = require('../../../utils/email');
        const user = await strapi.db.query('plugin::users-permissions.user').findOne({ where: { email } });
        if (!user) throw new Error('User not found');
        const token = crypto.randomBytes(20).toString('hex');
        await strapi.db.query('plugin::users-permissions.user').update({ where: { id: user.id }, data: { resetPasswordToken: token } });
        const resetLink = `https://ton-frontend.com/reset-password?token=${token}`;
        try {
            const { sendEmail } = require('../../../utils/email');
            await sendEmail(email, 'Password Reset',
                `Good morning! ${user.username},\n\nClick the link to reset your password:\n\n${resetLink}`);
        } catch (error) {
            console.error('Error sending email:', error.message);
            throw new Error('Failed to send reset email');
        }
        return { message: 'Password reset email sent' };
    },

    // ── getMe — now populates photo field ────────────────────────────────────
    async getMe(userId) {
        const user = await strapi.db.query('plugin::users-permissions.user').findOne({
            where: { id: userId }, populate: ['role'],
        });
        if (!user) throw new Error('User not found');

        let profile = null;
        if (user.user_role === 'player') {
            profile = await strapi.db.query('api::player.player').findOne({
                where:   { player: userId },
                populate: { player: true, photo: true },   // ← include photo
            });
        } else if (user.user_role === 'manager') {
            profile = await strapi.db.query('api::manager.manager').findOne({
                where:   { manager: userId },
                populate: { manager: true, photo: true },  // ← include photo
            });
        }

        // Build a convenient photoUrl string at the top level
        const baseUrl  = strapi.config.get('server.url') || '';
        const rawUrl   = profile?.photo?.url || null;
        const photoUrl = rawUrl
            ? (rawUrl.startsWith('http') ? rawUrl : `${baseUrl}${rawUrl}`)
            : null;

        return { user, profile, photoUrl };
    },

    async updateProfile(userId, { username, email, phone }) {
        const user = await strapi.db.query('plugin::users-permissions.user').findOne({ where: { id: userId } });
        if (!user) throw new Error('User not found');

        if (email && email !== user.email) {
            const existing = await strapi.db.query('plugin::users-permissions.user').findOne({ where: { email } });
            if (existing) throw new Error('Email already in use');
        }

        const updateUser = await strapi.db.query('plugin::users-permissions.user').update({
            where: { id: userId },
            data:  { username: username || user.username, email: email || user.email },
        });

        let updateProfile = null;
        if (user.user_role === 'player') {
            const profile = await strapi.db.query('api::player.player').findOne({ where: { player: userId } });
            if (profile && phone !== undefined) {
                updateProfile = await strapi.db.query('api::player.player').update({
                    where: { id: profile.id }, data: { phone: phone || profile.phone },
                });
            }
        } else if (user.user_role === 'manager') {
            const profile = await strapi.db.query('api::manager.manager').findOne({ where: { manager: userId } });
            if (profile && phone !== undefined) {
                updateProfile = await strapi.db.query('api::manager.manager').update({
                    where: { id: profile.id }, data: { phone: phone || profile.phone },
                });
            }
        }
        return { updateUser, updateProfile };
    },

    // ── updateFirebaseUid — also saves fcmToken ───────────────────────────────
    async updateFirebaseUid(userId, firebaseUid, fcmToken) {
        const user = await strapi.db.query('plugin::users-permissions.user').findOne({ where: { id: userId } });
        if (!user) throw new Error('User not found');

        const data = { firebaseUid };
        if (fcmToken && fcmToken.trim() !== '') data.fcmToken = fcmToken;

        let updatedProfile = null;
        if (user.user_role === 'player') {
            const profile = await strapi.db.query('api::player.player').findOne({ where: { player: userId } });
            if (!profile) throw new Error('Player profile not found');
            updatedProfile = await strapi.db.query('api::player.player').update({ where: { id: profile.id }, data });
            console.log(`✅ Player ${profile.id} firebase updated: uid=${firebaseUid}`);
        } else if (user.user_role === 'manager') {
            const profile = await strapi.db.query('api::manager.manager').findOne({ where: { manager: userId } });
            if (!profile) throw new Error('Manager profile not found');
            updatedProfile = await strapi.db.query('api::manager.manager').update({ where: { id: profile.id }, data });
            console.log(`✅ Manager ${profile.id} firebase updated: uid=${firebaseUid}`);
        } else {
            throw new Error('Invalid user role');
        }

        return { firebaseUid, fcmToken: fcmToken || null, profile: updatedProfile };
    },

    // ── updateProfilePhoto — links uploaded file ID to profile ───────────────
    // Called after the file has already been uploaded to Strapi media library.
    // Sets the `photo` single-media relation on the player or manager profile.
    // src/api/auth/services/auth.js

// ── updateProfilePhoto — links uploaded file ID to profile ───────────────
async updateProfilePhoto(userId, fileId) {
    const user = await strapi.db.query('plugin::users-permissions.user').findOne({ where: { id: userId } });
    if (!user) throw new Error('User not found');

    if (user.user_role === 'player') {
        const profile = await strapi.db.query('api::player.player').findOne({ where: { player: userId } });
        if (!profile) throw new Error('Player profile not found');
        await strapi.db.query('api::player.player').update({
            where: { id: profile.id },
            data: { photo: fileId },
        });
        console.log(`✅ Player ${profile.id} photo updated → file ${fileId}`);
    } else if (user.user_role === 'manager') {
        const profile = await strapi.db.query('api::manager.manager').findOne({ where: { manager: userId } });
        if (!profile) throw new Error('Manager profile not found');
        await strapi.db.query('api::manager.manager').update({
            where: { id: profile.id },
            data: { photo: fileId },
        });
        console.log(`✅ Manager ${profile.id} photo updated → file ${fileId}`);
    } else if (user.user_role === 'worker') {
        const profile = await strapi.db.query('api::worker.worker').findOne({ where: { worker: userId } });
        if (!profile) throw new Error('Worker profile not found');
        await strapi.db.query('api::worker.worker').update({
            where: { id: profile.id },
            data: { photo: fileId },
        });
        console.log(`✅ Worker ${profile.id} photo updated → file ${fileId}`);
    } else {
        throw new Error('Invalid user role — only players, managers, and workers have a photo field');
    }
},
};*/


















/*// src/api/auth/services/auth.js
// @ts-nocheck
const jwt    = require('jsonwebtoken');
const crypto = require('crypto');
const JWT_SECRET = process.env.JWT_SECRET || 'secret';

module.exports = {

    async registerUser({ username, email, password, phone }) {
        const existing = await strapi.db.query('plugin::users-permissions.user').findOne({ where: { email } });
        if (existing) throw new Error('User already exists');

        const role = await strapi.db.query('plugin::users-permissions.role').findOne({ where: { type: 'authenticated' } });

        const user = await strapi.plugins['users-permissions'].services.user.add({
            username, email, password, role: role.id, user_role: 'player',
        });
        console.log('User registered:', user.id);

        try {
            const profile = await strapi.db.query('api::player.player').create({
                data: { phone: phone || null, player: user.id },
            });
            console.log('Player profile created:', profile.id);
        } catch (error) {
            console.error('Error creating player profile:', error.message);
        }
        return user;
    },

    async loginUser({ email, password }) {
        const user = await strapi.db.query('plugin::users-permissions.user').findOne({ where: { email } });
        if (!user) throw new Error('User not found');
        const valid = await strapi.plugins['users-permissions'].services.user.validatePassword(password, user.password);
        if (!valid) throw new Error('Invalid password');
        const token = jwt.sign({ id: user.id, user_role: user.user_role }, JWT_SECRET, { expiresIn: '7d' });
        return { token, user };
    },

    async resetPassword(token, password) {
        const user = await strapi.db.query('plugin::users-permissions.user').findOne({ where: { resetPasswordToken: token } });
        if (!user) throw new Error('Invalid token');
        await strapi.plugins['users-permissions'].services.user.edit(user.id, { password });
        await strapi.db.query('plugin::users-permissions.user').update({ where: { id: user.id }, data: { resetPasswordToken: null } });
    },

    async changePassword(userId, oldPassword, newPassword) {
        const user = await strapi.db.query('plugin::users-permissions.user').findOne({ where: { id: userId } });
        if (!user) throw new Error('User not found');
        const valid = strapi.plugins['users-permissions'].services.user.validatePassword(oldPassword, user.password);
        if (!valid) throw new Error('Invalid old password');
        await strapi.plugins['users-permissions'].services.user.edit(user.id, { password: newPassword });
    },

    async forgotPassword(email) {
        const { sendEmail } = require('../../../utils/email');
        const user = await strapi.db.query('plugin::users-permissions.user').findOne({ where: { email } });
        if (!user) throw new Error('User not found');
        const token = crypto.randomBytes(20).toString('hex');
        await strapi.db.query('plugin::users-permissions.user').update({ where: { id: user.id }, data: { resetPasswordToken: token } });
        const resetLink = `https://ton-frontend.com/reset-password?token=${token}`;
        try {
            const { sendEmail } = require('../../../utils/email');
            await sendEmail(email, 'Password Reset',
                `Good morning! ${user.username},\n\nClick the link to reset your password:\n\n${resetLink}`);
        } catch (error) {
            console.error('Error sending email:', error.message);
            throw new Error('Failed to send reset email');
        }
        return { message: 'Password reset email sent' };
    },

    // ── getMe — now populates photo field ────────────────────────────────────
    async getMe(userId) {
        const user = await strapi.db.query('plugin::users-permissions.user').findOne({
            where: { id: userId }, populate: ['role'],
        });
        if (!user) throw new Error('User not found');

        let profile = null;
        if (user.user_role === 'player') {
            profile = await strapi.db.query('api::player.player').findOne({
                where:   { player: userId },
                populate: { player: true, photo: true },   // ← include photo
            });
        } else if (user.user_role === 'manager') {
            profile = await strapi.db.query('api::manager.manager').findOne({
                where:   { manager: userId },
                populate: { manager: true, photo: true },  // ← include photo
            });
        }

        // Build a convenient photoUrl string at the top level
        const baseUrl  = strapi.config.get('server.url') || '';
        const rawUrl   = profile?.photo?.url || null;
        const photoUrl = rawUrl
            ? (rawUrl.startsWith('http') ? rawUrl : `${baseUrl}${rawUrl}`)
            : null;

        return { user, profile, photoUrl };
    },

    async updateProfile(userId, { username, email, phone }) {
        const user = await strapi.db.query('plugin::users-permissions.user').findOne({ where: { id: userId } });
        if (!user) throw new Error('User not found');

        if (email && email !== user.email) {
            const existing = await strapi.db.query('plugin::users-permissions.user').findOne({ where: { email } });
            if (existing) throw new Error('Email already in use');
        }

        const updateUser = await strapi.db.query('plugin::users-permissions.user').update({
            where: { id: userId },
            data:  { username: username || user.username, email: email || user.email },
        });

        let updateProfile = null;
        if (user.user_role === 'player') {
            const profile = await strapi.db.query('api::player.player').findOne({ where: { player: userId } });
            if (profile && phone !== undefined) {
                updateProfile = await strapi.db.query('api::player.player').update({
                    where: { id: profile.id }, data: { phone: phone || profile.phone },
                });
            }
        } else if (user.user_role === 'manager') {
            const profile = await strapi.db.query('api::manager.manager').findOne({ where: { manager: userId } });
            if (profile && phone !== undefined) {
                updateProfile = await strapi.db.query('api::manager.manager').update({
                    where: { id: profile.id }, data: { phone: phone || profile.phone },
                });
            }
        }
        return { updateUser, updateProfile };
    },

    // ── updateFirebaseUid — also saves fcmToken ───────────────────────────────
    async updateFirebaseUid(userId, firebaseUid, fcmToken) {
        const user = await strapi.db.query('plugin::users-permissions.user').findOne({ where: { id: userId } });
        if (!user) throw new Error('User not found');

        const data = { firebaseUid };
        if (fcmToken && fcmToken.trim() !== '') data.fcmToken = fcmToken;

        let updatedProfile = null;
        if (user.user_role === 'player') {
            const profile = await strapi.db.query('api::player.player').findOne({ where: { player: userId } });
            if (!profile) throw new Error('Player profile not found');
            updatedProfile = await strapi.db.query('api::player.player').update({ where: { id: profile.id }, data });
            console.log(`✅ Player ${profile.id} firebase updated: uid=${firebaseUid}`);
        } else if (user.user_role === 'manager') {
            const profile = await strapi.db.query('api::manager.manager').findOne({ where: { manager: userId } });
            if (!profile) throw new Error('Manager profile not found');
            updatedProfile = await strapi.db.query('api::manager.manager').update({ where: { id: profile.id }, data });
            console.log(`✅ Manager ${profile.id} firebase updated: uid=${firebaseUid}`);
        } else {
            throw new Error('Invalid user role');
        }

        return { firebaseUid, fcmToken: fcmToken || null, profile: updatedProfile };
    },

    // ── updateProfilePhoto — links uploaded file ID to profile ───────────────
    // Called after the file has already been uploaded to Strapi media library.
    // Sets the `photo` single-media relation on the player or manager profile.
    async updateProfilePhoto(userId, fileId) {
        const user = await strapi.db.query('plugin::users-permissions.user').findOne({ where: { id: userId } });
        if (!user) throw new Error('User not found');

        if (user.user_role === 'player') {
            const profile = await strapi.db.query('api::player.player').findOne({ where: { player: userId } });
            if (!profile) throw new Error('Player profile not found');
            await strapi.db.query('api::player.player').update({
                where: { id: profile.id },
                data:  { photo: fileId },   // single-media field → just pass the file ID
            });
            console.log(`✅ Player ${profile.id} photo updated → file ${fileId}`);
        } else if (user.user_role === 'manager') {
            const profile = await strapi.db.query('api::manager.manager').findOne({ where: { manager: userId } });
            if (!profile) throw new Error('Manager profile not found');
            await strapi.db.query('api::manager.manager').update({
                where: { id: profile.id },
                data:  { photo: fileId },
            });
            console.log(`✅ Manager ${profile.id} photo updated → file ${fileId}`);
        } else {
            throw new Error('Invalid user role — only players and managers have a photo field');
        }
    },
};*/