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

    async login(ctx) {
        try {
           const data = await authService.loginUser(ctx.request.body);
           ctx.send(data);
        }   catch (error) {
            ctx.badRequest(error.message);
        }
    },

    async reset(ctx){
        try{
            await authService.resetPassword(ctx.request.body.token, ctx.request.body.password);
            ctx.send({message : "Password reset successful"});
        } catch (error) {
            ctx.badRequest(error.message);
        }



    },


    async change(ctx){
        try{
            const user = ctx.state.user;
            if (!user) return ctx.unauthorized("You must be logged in to change password");
            const {oldPassword, newPassword} = ctx.request.body;
            if (!oldPassword || !newPassword) return ctx.badRequest("Old password and new password are required");
            await authService.changePassword(user.id, oldPassword, newPassword);
            ctx.send({message : "Password changed successfully"});   
        } catch (error) {
            ctx.badRequest(error.message);
        }
    }

}