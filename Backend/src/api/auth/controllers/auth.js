// src/api/auth/controllers/auth.js
// @ts-nocheck
const authService = require('../services/auth');

module.exports = {
    async register(ctx) {
        try {
            const user = await authService.registerUser(ctx.request.body);
            ctx.send(user);
        } catch (error) {
            ctx.badRequest(error.message);
        }
    },
// hedhiya backup lel register lo5ra mta3 l'admin
    async register_manager(ctx) {
        try {
            const currentUser = ctx.state.user;
            if (!currentUser || currentUser.user_role !== 'admin') {
                return ctx.unauthorized('Only admin can create manager accounts');
            }
            const user = await authService.registerManager(ctx.request.body);
            ctx.send(user);
        } catch (error) {
            ctx.badRequest(error.message);
        }
    },

    async login(ctx) {
        try {
            const data = await authService.loginUser(ctx.request.body);
            ctx.send(data);
        } catch (error) {
            ctx.badRequest(error.message);
        }
    },

    async reset(ctx) {
        try {
            await authService.resetPassword(ctx.request.body.token, ctx.request.body.password);
            ctx.send({ message: 'Password reset successful' });
        } catch (error) {
            ctx.badRequest(error.message);
        }
    },

    async change(ctx) {
        try {
            const user = ctx.state.user;
            if (!user) return ctx.unauthorized('You must be logged in to change password');
            const { oldPassword, newPassword } = ctx.request.body;
            if (!oldPassword || !newPassword)
                return ctx.badRequest('Old password and new password are required');
            await authService.changePassword(user.id, oldPassword, newPassword);
            ctx.send({ message: 'Password changed successfully' });
        } catch (error) {
            ctx.badRequest(error.message);
        }
    },

    async forgot(ctx) {
        try {
            await authService.forgotPassword(ctx.request.body.email);
            ctx.send({ message: 'Reset link has been sent' });
        } catch (error) {
            ctx.badRequest(error.message);
        }
    },

    async me(ctx) {
        try {
            const user = ctx.state.user;
            if (!user) return ctx.unauthorized('You must be logged in');
            const data = await authService.getMe(user.id);
            ctx.send(data);
        } catch (error) {
            ctx.badRequest(error.message);
        }
    },

    async update(ctx) {
        try {
            const user = ctx.state.user;
            if (!user) return ctx.unauthorized('You must be logged in to update profile');
            const updatedUser = await authService.updateProfile(user.id, ctx.request.body);
            ctx.send(updatedUser);
        } catch (error) {
            ctx.badRequest(error.message);
        }
    },
// hedhi bech kol login y'updati el firebaseUid mta3ou w ykoun 3ando fcmToken ken 7ab yeb3ath notification lel app
    async updateFirebaseUid(ctx) {
        try {
            const user = ctx.state.user;
            if (!user) return ctx.unauthorized('You must be logged in');
            const { firebaseUid, fcmToken } = ctx.request.body;
            if (!firebaseUid || firebaseUid.trim() === '')
                return ctx.badRequest('firebaseUid is required');
            const result = await authService.updateFirebaseUid(user.id, firebaseUid, fcmToken);
            ctx.send({
                success: true,
                message: 'Firebase identity updated',
                firebaseUid: result.firebaseUid,
                fcmToken: result.fcmToken || null,
            });
        } catch (error) {
            console.error('Error updating Firebase UID:', error);
            ctx.badRequest(error.message);
        }
    },

    // ─────────────────────────────────────────────────────────────────────────
    // POST /auth/upload-photo
    // multipart/form-data  field: "photo"  (jpg / png / webp)
    //
    // 1. Uploads the file to Strapi's upload plugin (media library)
    // 2. Links the uploaded file ID to the player or manager profile
    //    using the "photo" single-media field you added to both tables
    // 3. Returns { photoUrl, photoId }
    // ─────────────────────────────────────────────────────────────────────────
    // src/api/auth/controllers/auth.js

// POST /auth/upload-photo
// ma9soumin 3la 2 parties , wa7da tuploadi w lo5ra tlinki
async uploadPhoto(ctx) {
    try {
        const user = ctx.state.user;
        if (!user) return ctx.unauthorized('You must be logged in');

        const files = ctx.request.files;
        if (!files || (!files.photo && !files['photo'])) {
            return ctx.badRequest('No photo file provided. Send multipart/form-data with field "photo".');
        }

        const photoFile = files.photo;

        const uploadedFiles = await strapi.plugins.upload.services.upload.upload({
            data: {
                fileInfo: {
                    name: photoFile.name || photoFile.originalFilename || 'profile-photo',
                    alternativeText: `Profile photo for user ${user.id}`,
                    caption: '',
                },
            },
            files: photoFile,
        });

        if (!uploadedFiles || uploadedFiles.length === 0) {
            return ctx.badRequest('Upload failed — no file returned from storage.');
        }

        const uploadedFile = uploadedFiles[0];
        const fileId = uploadedFile.id;
        const fileUrl = uploadedFile.url;

        const baseUrl = strapi.config.get('server.url') || '';
        const absoluteUrl = fileUrl.startsWith('http') ? fileUrl : `${baseUrl}${fileUrl}`;

        //  Link to player, manager, or worker profile 
        await authService.updateProfilePhoto(user.id, fileId);

        ctx.send({
            success: true,
            photoUrl: absoluteUrl,
            photoId: fileId,
            message: 'Profile photo updated successfully',
        });

    } catch (error) {
        console.error('[uploadPhoto] error:', error);
        ctx.badRequest(error.message || 'Failed to upload photo');
    }
},
};

















/*// src/api/auth/controllers/auth.js
// @ts-nocheck
const authService = require('../services/auth');

module.exports = {
    async register(ctx) {
        try {
            const user = await authService.registerUser(ctx.request.body);
            ctx.send(user);
        } catch (error) {
            ctx.badRequest(error.message);
        }
    },

    async register_manager(ctx) {
        try {
            const currentUser = ctx.state.user;
            if (!currentUser || currentUser.user_role !== 'admin') {
                return ctx.unauthorized('Only admin can create manager accounts');
            }
            const user = await authService.registerManager(ctx.request.body);
            ctx.send(user);
        } catch (error) {
            ctx.badRequest(error.message);
        }
    },

    async login(ctx) {
        try {
            const data = await authService.loginUser(ctx.request.body);
            ctx.send(data);
        } catch (error) {
            ctx.badRequest(error.message);
        }
    },

    async reset(ctx) {
        try {
            await authService.resetPassword(ctx.request.body.token, ctx.request.body.password);
            ctx.send({ message: 'Password reset successful' });
        } catch (error) {
            ctx.badRequest(error.message);
        }
    },

    async change(ctx) {
        try {
            const user = ctx.state.user;
            if (!user) return ctx.unauthorized('You must be logged in to change password');
            const { oldPassword, newPassword } = ctx.request.body;
            if (!oldPassword || !newPassword)
                return ctx.badRequest('Old password and new password are required');
            await authService.changePassword(user.id, oldPassword, newPassword);
            ctx.send({ message: 'Password changed successfully' });
        } catch (error) {
            ctx.badRequest(error.message);
        }
    },

    async forgot(ctx) {
        try {
            await authService.forgotPassword(ctx.request.body.email);
            ctx.send({ message: 'Reset link has been sent' });
        } catch (error) {
            ctx.badRequest(error.message);
        }
    },

    async me(ctx) {
        try {
            const user = ctx.state.user;
            if (!user) return ctx.unauthorized('You must be logged in');
            const data = await authService.getMe(user.id);
            ctx.send(data);
        } catch (error) {
            ctx.badRequest(error.message);
        }
    },

    async update(ctx) {
        try {
            const user = ctx.state.user;
            if (!user) return ctx.unauthorized('You must be logged in to update profile');
            const updatedUser = await authService.updateProfile(user.id, ctx.request.body);
            ctx.send(updatedUser);
        } catch (error) {
            ctx.badRequest(error.message);
        }
    },

    async updateFirebaseUid(ctx) {
        try {
            const user = ctx.state.user;
            if (!user) return ctx.unauthorized('You must be logged in');
            const { firebaseUid, fcmToken } = ctx.request.body;
            if (!firebaseUid || firebaseUid.trim() === '')
                return ctx.badRequest('firebaseUid is required');
            const result = await authService.updateFirebaseUid(user.id, firebaseUid, fcmToken);
            ctx.send({
                success: true,
                message: 'Firebase identity updated',
                firebaseUid: result.firebaseUid,
                fcmToken: result.fcmToken || null,
            });
        } catch (error) {
            console.error('Error updating Firebase UID:', error);
            ctx.badRequest(error.message);
        }
    },

    // ─────────────────────────────────────────────────────────────────────────
    // POST /auth/upload-photo
    // multipart/form-data  field: "photo"  (jpg / png / webp)
    //
    // 1. Uploads the file to Strapi's upload plugin (media library)
    // 2. Links the uploaded file ID to the player or manager profile
    //    using the "photo" single-media field you added to both tables
    // 3. Returns { photoUrl, photoId }
    // ─────────────────────────────────────────────────────────────────────────
    async uploadPhoto(ctx) {
        try {
            const user = ctx.state.user;
            if (!user) return ctx.unauthorized('You must be logged in');

            // ctx.request.files comes from koa-body multipart parsing
            const files = ctx.request.files;
            if (!files || (!files.photo && !files['photo'])) {
                return ctx.badRequest('No photo file provided. Send multipart/form-data with field "photo".');
            }

            const photoFile = files.photo;

            // ── Upload to Strapi media library ──────────────────────────────
            // strapi.plugins.upload.services.upload.upload() expects:
            // { data: { fileInfo: {} }, files: <file-object> }
            const uploadedFiles = await strapi.plugins.upload.services.upload.upload({
                data: {
                    fileInfo: {
                        name:              photoFile.name || photoFile.originalFilename || 'profile-photo',
                        alternativeText:   `Profile photo for user ${user.id}`,
                        caption:           '',
                    },
                },
                files: photoFile,
            });

            if (!uploadedFiles || uploadedFiles.length === 0) {
                return ctx.badRequest('Upload failed — no file returned from storage.');
            }

            const uploadedFile = uploadedFiles[0];
            const fileId       = uploadedFile.id;
            const fileUrl      = uploadedFile.url;

            // Build absolute URL (needed for local dev with relative URLs)
            const baseUrl      = strapi.config.get('server.url') || '';
            const absoluteUrl  = fileUrl.startsWith('http') ? fileUrl : `${baseUrl}${fileUrl}`;

            // ── Link to player or manager profile ───────────────────────────
            await authService.updateProfilePhoto(user.id, fileId);

            ctx.send({
                success:  true,
                photoUrl: absoluteUrl,
                photoId:  fileId,
                message:  'Profile photo updated successfully',
            });

        } catch (error) {
            console.error('[uploadPhoto] error:', error);
            ctx.badRequest(error.message || 'Failed to upload photo');
        }
    },
};*/