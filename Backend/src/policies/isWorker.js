// @ts-nocheck
const { errors } = require("@strapi/utils");

module.exports = async (ctx) => {
  const user = ctx.state.user;

  if (!user || user.user_role !== 'worker') {
    const msg = 'You need to be a worker to access this resource.';
    console.log(msg);

    ctx.status = 403;
    ctx.body = {
      data: null,
      error: {
        status: 403,
        name: 'ForbiddenError',
        message: msg,
        details: {},
      },
    };
    return false;
  }

  // Check if worker has a valid worker profile
  if (!user.workerId) {
    const msg = 'Worker profile not found. Please contact your manager.';
    console.log(msg);

    ctx.status = 403;
    ctx.body = {
      data: null,
      error: {
        status: 403,
        name: 'ForbiddenError',
        message: msg,
        details: {},
      },
    };
    return false;
  }

  console.log(`Access granted to worker: ${user.username} (ID: ${user.id}, WorkerProfile: ${user.workerId})`);
  return true;
};