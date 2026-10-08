// @ts-nocheck
'use strict';

module.exports = {
  /**
   * An asynchronous register function that runs before
   * your application is initialized.
   *
   * This gives you an opportunity to extend code.
   */
  register(/*{ strapi }*/) {},

  /**
   * An asynchronous bootstrap function that runs before
   * your application gets started.
   *
   * This gives you an opportunity to set up your data model,
   * run jobs, or perform some special logic.
   */
 
   async bootstrap({ strapi }) {

     if (!process.env.OPENROUTER_API_KEY) {
      strapi.log.warn('[ai-agent] OPENROUTER_API_KEY missing in .env');
    }

    const exist = await strapi.db.query("plugin::users-permissions.user").findOne({
      where : {email : "admin@gmail.com"}
    });

  
  if(!exist){
    const role = await strapi.db.query("plugin::users-permissions.role").findOne({
      where : {type : "authenticated"}
    });


  const user = await strapi.plugins['users-permissions'].services.user.add({
    username : "admin",
    email : "admin@gmail.com",
    password : "admin123",
    role : role.id,
    user_role : "admin"
  });
  console.log("Admin Created Successfully");
  }  
  },
};
