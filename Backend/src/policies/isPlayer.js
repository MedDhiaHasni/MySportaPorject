// @ts-nocheck
const { errors } = require("@strapi/utils");

module.exports = async (ctx) => {
    const user = ctx.state.user;

    if (!user || user.user_role !== 'player') {
        const msg = 'You need to be a player to access this resource.';
        console.log(msg);

        ctx.status = 403;
        ctx.body = {
            data: null,
            error: {
                status: 403,
                name: 'ForbiddenError',
                message: msg,
                details: {}
            }
        };
        return false;
    }

    console.log(`Access granted to player: ${user.username} (ID: ${user.id})`);
    return true;
};