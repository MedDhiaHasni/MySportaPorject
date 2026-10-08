const {errors} = require("@strapi/utils");

module.exports = async (/** @type {{ state: number; body: { data: null; error: { status: number; name: string; message: string; details: {}; }; }; }} */ ctx) => {
    // @ts-ignore
    const user = ctx.state.user;

    if (!user || user.user_role !== 'admin') {
        const msg = 'You need to be an admin to access this resource.';
        console.log(msg);

        ctx.state = 403;
        ctx.body = {
            data: null, 
            error: {
                status: 403,
                name: 'ForbiddenError',
                message: msg,
                details : {}
            }  
        };
        return false ;




    }
    console.log(`Access granted to admin : ${user.username}`);
    return true;

} 