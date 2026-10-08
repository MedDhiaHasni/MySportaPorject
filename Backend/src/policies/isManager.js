// @ts-nocheck
const { errors } = require("@strapi/utils");

module.exports = async (ctx) => {
    const user = ctx.state.user;

    // Check if user exists and has manager role
    if (!user || user.user_role !== 'manager') {
        const msg = 'You need to be a manager to access this resource.';
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
    
    // Check if manager has a valid manager profile
    if (!user.managerId) {
        const msg = 'Manager profile not found. Please contact admin.';
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
    
    console.log(`Access granted to manager: ${user.username} (ID: ${user.id}, ManagerProfile: ${user.managerId})`);
    return true;
};





/*const { errors } = require("@strapi/utils");

module.exports = async (ctx) => {
    const user = ctx.state.user;

    if (!user || user.user_role !== 'manager') {
        const msg = 'You need to be a manager to access this resource.';
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
    
    console.log(`Access granted to manager: ${user.username} (ID: ${user.id})`);
    return true;
};*/