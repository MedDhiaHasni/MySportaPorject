'use strict';

module.exports = {
    routes: [
        {
            method: "GET",
            path: "/courts",
            handler: "court.getCourts",
            config: {
                auth: false,
                policies: ["global::authMiddleware", "global::isManager"]
            }
        },
        {
            method: "GET",
            path: "/courts/:id",
            handler: "court.getCourt",
            config: {
                auth: false,
                policies: ["global::authMiddleware", "global::isManager"]
            }
        },
        {
            method: "POST",
            path: "/courts",
            handler: "court.createCourt",
            config: {
                auth: false,
                policies: ["global::authMiddleware", "global::isManager"]
            }
        },
        {
            method: "PUT",
            path: "/courts/:id",
            handler: "court.updateCourt",
            config: {
                auth: false,
                policies: ["global::authMiddleware", "global::isManager"]
            }
        },
        {
            method: "DELETE",
            path: "/courts/:id",
            handler: "court.deleteCourt",
            config: {
                auth: false,
                policies: ["global::authMiddleware", "global::isManager"]
            }
        },
        // NEW: Assign worker to court
        {
            method: "POST",
            path: "/courts/:id/assign-worker",
            handler: "court.assignWorker",
            config: {
                auth: false,
                policies: ["global::authMiddleware", "global::isManager"]
            }
        },
        // NEW: Remove worker from court
        {
            method: "DELETE",
            path: "/courts/:id/remove-worker",
            handler: "court.removeWorker",
            config: {
                auth: false,
                policies: ["global::authMiddleware", "global::isManager"]
            }
        }
    ]
};









/*'use strict';

module.exports = {
    routes: [
        {
            method: "GET",
            path: "/courts",
            handler: "court.getCourts",
            config: {
                auth: false,
                policies: ["global::authMiddleware", "global::isManager"]
            }
        },
        {
            method: "GET",
            path: "/courts/:id",
            handler: "court.getCourt",
            config: {
                auth: false,
                policies: ["global::authMiddleware", "global::isManager"]
            }
        },
        {
            method: "POST",
            path: "/courts",
            handler: "court.createCourt",
            config: {
                auth: false,
                policies: ["global::authMiddleware", "global::isManager"]
            }
        },
        {
            method: "PUT",
            path: "/courts/:id",
            handler: "court.updateCourt",
            config: {
                auth: false,
                policies: ["global::authMiddleware", "global::isManager"]
            }
        },
        {
            method: "DELETE",
            path: "/courts/:id",
            handler: "court.deleteCourt",
            config: {
                auth: false,
                policies: ["global::authMiddleware", "global::isManager"]
            }
        }
    ]
};*/