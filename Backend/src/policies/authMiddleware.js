// @ts-nocheck
const jwt = require('jsonwebtoken');
const JWT_SECRET = process.env.JWT_SECRET || "secret";

module.exports = async (ctx) => {
    const authHeader = ctx.request.header.authorization;

    if (!authHeader) {
        return false;
    }

    const token = authHeader.split(" ")[1];

    if (!token) {
        return false;
    }

    try {
        const decoded = jwt.verify(token, JWT_SECRET);
        // @ts-ignore
        const userId = decoded?.id;

        if (!userId) {
            return false;
        }

        const user = await strapi.db
            .query("plugin::users-permissions.user")
            .findOne({
                where: { id: userId },
            });

        if (!user) {
            return false;
        }

        console.log("USER FROM DB:", user);

        // Get manager profile ID if user is a manager
        let managerId = null;
        if (user.user_role === 'manager') {
            const manager = await strapi.db.query("api::manager.manager").findOne({
                where: { manager: user.id }
            });
            managerId = manager?.id;
            console.log("MANAGER PROFILE ID:", managerId);
        }

        // Get player profile ID if user is a player
        let playerId = null;
        if (user.user_role === 'player') {
            const player = await strapi.db.query("api::player.player").findOne({
                where: { player: user.id }
            });
            playerId = player?.id;
            console.log("PLAYER PROFILE ID:", playerId);
        }

        // Get worker profile ID if user is a worker
        let workerId = null;
        if (user.user_role === 'worker') {
            const worker = await strapi.db.query("api::worker.worker").findOne({
                where: { worker: user.id }
            });
            workerId = worker?.id;
            console.log("WORKER PROFILE ID:", workerId);
        }

        ctx.state.user = {
            id: user.id,
            email: user.email,
            username: user.username,
            user_role: user.user_role,
            managerId: managerId,
            playerId: playerId,
            workerId: workerId,
        };

        return true;
    } catch (err) {
        console.log("JWT ERROR:", err.message);
        return false;
    }
};













/*// @ts-nocheck
const jwt = require('jsonwebtoken');
const JWT_SECRET = process.env.JWT_SECRET || "secret";

module.exports = async (ctx) => {
    const authHeader = ctx.request.header.authorization;

    if (!authHeader) {
        return false;
    }

    const token = authHeader.split(" ")[1];

    if (!token) {
        return false;
    }

    try {
        const decoded = jwt.verify(token, JWT_SECRET);
        // @ts-ignore
        const userId = decoded?.id;

        if (!userId) {
            return false;
        }

        const user = await strapi.db
            .query("plugin::users-permissions.user")
            .findOne({
                where: { id: userId },
            });

        if (!user) {
            return false;
        }

        console.log("USER FROM DB:", user);

        // Get manager profile ID if user is a manager
        let managerId = null;
        if (user.user_role === 'manager') {
            const manager = await strapi.db.query("api::manager.manager").findOne({
                where: { manager: user.id }
            });
            managerId = manager?.id;
            console.log("MANAGER PROFILE ID:", managerId);
        }

        // Get player profile ID if user is a player
        let playerId = null;
        if (user.user_role === 'player') {
            const player = await strapi.db.query("api::player.player").findOne({
                where: { player: user.id }
            });
            playerId = player?.id;
            console.log("PLAYER PROFILE ID:", playerId);
        }

        ctx.state.user = {
            id: user.id,
            email: user.email,
            username: user.username,
            user_role: user.user_role,
            managerId: managerId,
            playerId: playerId,  // Add playerId for player users
        };

        return true;
    } catch (err) {
        console.log("JWT ERROR:", err.message);
        return false;
    }
};

************************

const jwt = require('jsonwebtoken');
const JWT_SECRET = process.env.JWT_SECRET || "secret";

module.exports = async (ctx) => {
    const authHeader = ctx.request.header.authorization;

    if (!authHeader) {
        return false;
    }

    const token = authHeader.split(" ")[1];

    if (!token) {
        return false;
    }

    try {
        const decoded = jwt.verify(token, JWT_SECRET);
        // @ts-ignore
        const userId = decoded?.id;

        if (!userId) {
            return false;
        }

        const user = await strapi.db
            .query("plugin::users-permissions.user")
            .findOne({
                where: { id: userId },
            });

        if (!user) {
            return false;
        }

        console.log("USER FROM DB:", user);

        ctx.state.user = {
            id: user.id,
            email: user.email,
            username: user.username,
            user_role: user.user_role,
        };

        return true;
    } catch (err) {
        console.log("JWT ERROR:", err.message);
        return false;
    }
};*/ 