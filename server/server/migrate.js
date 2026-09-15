require('dotenv').config(); const fs=require('fs'); const {pool}=require('./db');
(async()=>{try{await pool.query(fs.readFileSync(__dirname+'/schema.sql','utf8')); console.log('Database ready');}catch(e){console.error(e);process.exitCode=1}finally{await pool.end()}})();
