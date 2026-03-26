const jwt = require('jsonwebtoken');
const JWT_SECRET = process.env.JWT_SECRET || "secret";

module.exports = async (ctx, next) => {
  const authHeader = ctx.request.header.authorization;

  if (!authHeader) {
    console.log("Middleware JWT : pas de token");
    ctx.status = 401;
    ctx.body = { message: "No token" };
    return;
  }

  const token = authHeader.split(" ")[1];
  if (!token) {
    console.log("Middleware JWT : token mal formaté");
    ctx.status = 401;
    ctx.body = { message: "Token invalid" };
    return;
  }

  try {
    const decoded = jwt.verify(token, JWT_SECRET);
    const userId = typeof decoded === 'object' && decoded !== null ? decoded.id : null;

    if (!userId) {
      console.log("Middleware JWT : id utilisateur manquant dans token");
      ctx.status = 401;
      ctx.body = { message: "Token invalid" };
      return;
    }

    const user = await strapi.db.query("plugin::users-permissions.user").findOne({ where: { id: userId } });
    if (!user) {
      console.log("Middleware JWT : utilisateur introuvable");
      ctx.status = 401;
      ctx.body = { message: "Utilisateur introuvable" };
      return;
    }

    console.log("Middleware JWT : utilisateur connecté", user.email);
    ctx.state.user = user;

    // ✅ passer au middleware suivant
    await next();
  } catch (err) {
    console.log("Middleware JWT : token invalide ou expiré", err.message);
    ctx.status = 401;
    ctx.body = { message: "Token invalid" };
  }
};