const jwt=require('jsonwebtoken'); const bcrypt=require('bcryptjs'); const {query}=require('./db');
const secret=process.env.JWT_SECRET;
function sign(user){return jwt.sign({sub:user.id,role:user.role,name:user.name,email:user.email},secret,{expiresIn:process.env.JWT_EXPIRES_IN||'7d'});}
async function hash(p){return bcrypt.hash(p,12)} async function compare(p,h){return bcrypt.compare(p,h)}
function requireAuth(req,res,next){try{const h=req.headers.authorization||'';if(!h.startsWith('Bearer '))return res.status(401).json({error:'Authentication required'});req.user=jwt.verify(h.slice(7),secret);next()}catch{return res.status(401).json({error:'Invalid or expired token'})}}
function requireRole(...roles){return (req,res,next)=>roles.includes(req.user.role)?next():res.status(403).json({error:'Insufficient permissions'})}
module.exports={sign,hash,compare,requireAuth,requireRole};
