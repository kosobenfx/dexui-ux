# Dexillionz Global Marketplace

Production-ready B2B/B2C marketplace foundation using Node.js, Express, PostgreSQL/Supabase, Socket.IO and Resend.

## Dexillionz Secure Payments

Stripe has been removed. Checkout now supports two platform workflows:

### 1. Dexillionz Protected Payment
Buyer → payment reported/confirmed → order fulfillment → buyer confirms delivery & inspection → dispute period expires → seller share becomes releasable → authorized settlement releases seller funds.

The application keeps a payment transaction, immutable-style ledger entries, seller release records, dispute deadline and authorization trail.

### 2. Direct Seller Wire
Shipping/payment terms confirmed → buyer wires seller directly → buyer reports the transfer → seller confirms receipt → buyer confirms delivery/inspection → authorized Dexillionz agent releases the goods.

For direct-wire orders, the platform does **not** pretend to have custody of the seller's bank transfer. Seller confirmation and agent release are explicit workflow steps.

## Important payment/compliance note

The software implements the marketplace workflow, transaction records and authorization controls. It does not by itself create a bank account, move fiat money, or make a regulated escrow service legal. Before live launch, connect the protected-payment flow to an appropriately regulated bank/payment/escrow institution and complete required KYC/AML, safeguarding, licensing, chargeback/refund, tax and data-protection requirements for every country served.

## Supabase

Set `DATABASE_URL` to the Supabase Postgres connection string with SSL enabled. Run:

```bash
npm install
npm run migrate
npm run seed
npm start
```

## Payment configuration

Set these environment variables for the platform receiving protected-payment funds:

- `PAYMENT_BENEFICIARY_NAME`
- `PAYMENT_BANK_NAME`
- `PAYMENT_ACCOUNT_NAME`
- `PAYMENT_ACCOUNT_NUMBER`
- `PAYMENT_ROUTING_CODE`
- `PAYMENT_SWIFT`
- `PAYMENT_IBAN`
- `PROTECTION_FEE_RATE`
- `DISPUTE_PERIOD_DAYS`

Seller bank details are stored separately and remain unverified until your admin verification process is completed.

## Resend

`RESEND_API_KEY` and `EMAIL_FROM` are used for marketplace broadcast email. Keep the API key server-side and never commit `.env.production`.

## Production security

Use HTTPS, secure hosting, database backups, secret management, webhook/bank reconciliation, audit logging, KYC/AML controls, rate limits, monitoring and a regulated payment/escrow arrangement before accepting real customer funds.

Never commit `.env`, `.env.production`, database passwords or email API keys to Git.

## Production deployment notes

- The `prestart` script automatically runs `server/migrate.js` before `npm start`, creating/updating the PostgreSQL schema from `server/schema.sql` using `IF NOT EXISTS` statements.
- Do not commit `.env.production` or any real secrets. Configure all environment variables in Render's Environment settings.
- Render health checks can use `/api/health`.
- The frontend is resilient to `/api/products` failures: it renders the marketplace shell and shows a retry message instead of a blank page.
- The protected-payment workflow is a software workflow/ledger until a properly regulated banking/payment/escrow settlement provider is connected.

## Render + Supabase deployment

This repository is structured with the application files at the repository root so it can be connected directly to a Render Web Service.

1. Create/open your Supabase project and click **Connect**.
2. Copy a PostgreSQL connection string suitable for an application server (the Supabase **Session pooler** connection is a good choice for Render).
3. In Render, open the service's **Environment** page and add:
   - `DATABASE_URL` = your complete Supabase PostgreSQL connection string
   - `JWT_SECRET` = a long random secret
   - `ADMIN_BOOTSTRAP_PASSWORD` = a strong temporary admin bootstrap password
   - `APP_URL` = your Render service URL
   - `CORS_ORIGIN` = your frontend/origin URL
4. Save and deploy. Render supports environment variables for secret values; do not commit the database password or other secrets to Git.
5. The `prestart` script runs `server/migrate.js`, which creates the application schema when the service starts.

### Important

Never put the real Supabase password into `.env.example`, `render.yaml`, GitHub, or this ZIP. The `DATABASE_URL` entry in `render.yaml` is intentionally `sync: false` so Render asks you to supply the secret in the dashboard.
