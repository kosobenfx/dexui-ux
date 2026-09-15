const { Pool } = require('pg');

const databaseUrl = process.env.DATABASE_URL;

if (!databaseUrl || !databaseUrl.trim()) {
  console.error('DATABASE_URL is not configured. Add the Supabase PostgreSQL connection string in Render → Environment → Environment Variables.');
  process.exit(1);
}

// Supabase PostgreSQL requires TLS for hosted connections. Render production
// deployments should therefore use SSL. rejectUnauthorized:false is used
// because Supabase's managed certificate chain may not be present in the
// container's local CA bundle.
const isProduction = process.env.NODE_ENV === 'production';
const isSupabase = /supabase\.(co|com)|pooler\.supabase/i.test(databaseUrl);

const pool = new Pool({
  connectionString: databaseUrl,
  ssl: isProduction || isSupabase ? { rejectUnauthorized: false } : false,
  max: Number(process.env.DB_POOL_MAX || 10),
  idleTimeoutMillis: Number(process.env.DB_IDLE_TIMEOUT_MS || 30000),
  connectionTimeoutMillis: Number(process.env.DB_CONNECTION_TIMEOUT_MS || 10000),
});

pool.on('error', (err) => {
  console.error('Unexpected PostgreSQL pool error:', err);
});

module.exports = {
  pool,
  query: (text, params) => pool.query(text, params),
};
