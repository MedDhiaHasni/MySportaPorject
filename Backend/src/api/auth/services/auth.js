const jwt = require("jsonwebtoken");
const JWT_SECRET = process.env.JWT_SECRET || "secret";
module.exports = {
    async registerUser({username, email, password}) {
        const existing = await strapi.db.query("plugin::users-permissions.user").findOne({
            where : {email}
        });

        if(existing) throw new Error("User already exists");

        const role = await strapi.db.query("plugin::users-permissions.role").findOne({
            where : {type : "authenticated"}
        });

        const user = await strapi.plugins['users-permissions'].services.user.add({
            username,
            email,
            password,
            role : role.id,
            user_role : "player"
        });
        return user;
    },

    async loginUser({email, password}) {
        const user = await strapi.db.query("plugin::users-permissions.user").findOne({
            where : {email}
        });

        if(!user) throw new Error("User not found");
        const valid = await strapi.plugins['users-permissions'].services.user.validatePassword(password, user.password); 
        if(!valid) throw new Error("Invalid password"); 

        const token = jwt.sign({id : user.id, user_role : user.user_role}, JWT_SECRET, {expiresIn : "7d"});
        return {token, user};
    }, 

    async resetPassword (token,password){
        const user = await strapi.db.query("plugin::users-permissions.user").findOne({
            where : {resetPasswordToken : token}
        });
        if(!user) throw new Error("Invalid token");

        await strapi.plugins['users-permissions'].services.user.edit(user.id, {password});
        await strapi.db.query("plugin::users-permissions.user").update({
            where : {id : user.id},
            data : {resetPasswordToken : null}
        });
    },



    async changePassword(userId, oldPassword, newPassword){
        const user = await strapi.db.query("plugin::users-permissions.user").findOne({
            where : {id : userId}
        });
        if (!user) throw new Error("User not found");

        const  valid = strapi.plugins['users-permissions'].services.user.validatePassword(oldPassword, user.password); 
        if(!valid) throw new Error("Invalid old password");

        await strapi.plugins['users-permissions'].services.user.edit(user.id, {password : newPassword});
    }
}
