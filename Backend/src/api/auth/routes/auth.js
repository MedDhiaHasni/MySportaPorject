module.exports = {
    routes: [
        {
            method : "POST",
            path : "/auth/register",
            handler : "auth.register",
            config : {
                auth:false
            }
        },
        {
            method : "POST",
            path : "/auth/login",
            handler : "auth.login",
            config : {
                auth:false
            }
        },
         {
            method : "POST",
            path : "/auth/reset",
            handler : "auth.reset",
            config : {
                auth:false
            }
        },
         {
            method : "POST",
            path : "/auth/change",
            handler : "auth.change",
            config : {
                auth : false,
                policies :['global::authMiddleware']
            }
        }

    ]   
}