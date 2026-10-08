// src/api/auth/routes/auth.js
module.exports = {
    routes: [
        {
            method: 'POST',
            path: '/auth/register',
            handler: 'auth.register',
            config: { auth: false },
        },
        {
            method: 'POST',
            path: '/auth/login',
            handler: 'auth.login',
            config: { auth: false },
        },
        {
            method: 'POST',
            path: '/auth/reset',
            handler: 'auth.reset',
            config: { auth: false },
        },
        {
            method: 'POST',
            path: '/auth/forgot',
            handler: 'auth.forgot',
            config: { auth: false },
        },
        {
            method: 'POST',
            path: '/auth/change',
            handler: 'auth.change',
            config: { auth: false, policies: ['global::authMiddleware'] },
        },
        {
            method: 'GET',
            path: '/auth/me',
            handler: 'auth.me',
            config: { auth: false, policies: ['global::authMiddleware'] },
        },
        {
            method: 'PUT',
            path: '/auth/update',
            handler: 'auth.update',
            config: { auth: false, policies: ['global::authMiddleware'] },
        },
        {
            method: 'PUT',
            path: '/auth/update-firebase-uid',
            handler: 'auth.updateFirebaseUid',
            config: { auth: false, policies: ['global::authMiddleware'] },
        },
        // ─────────────────────────────────────────────────────────────────────
        // POST /auth/upload-photo
        // Accepts multipart/form-data with field "photo" (image file).
        // Uploads to Strapi media library, links the file to the
        // player or manager profile, returns the full photo URL.
        // ─────────────────────────────────────────────────────────────────────
        {
            method: 'POST',
            path: '/auth/upload-photo',
            handler: 'auth.uploadPhoto',
            config: { auth: false, policies: ['global::authMiddleware'] },
        },
    ],
};