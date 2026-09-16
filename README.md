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
   - `ADMIN_EMAIL` = the administrator email. The admin password is configured to match this email as requested.
   - `APP_URL` = your Render service URL
   - `CORS_ORIGIN` = your frontend/origin URL
4. Save and deploy. Render supports environment variables for secret values; do not commit the database password or other secrets to Git.
5. The `prestart` script runs `server/migrate.js`, which creates the application schema when the service starts.

### Important

Never put the real Supabase password into `.env.example`, `render.yaml`, GitHub, or this ZIP. The `DATABASE_URL` entry in `render.yaml` is intentionally `sync: false` so Render asks you to supply the secret in the dashboard.

### Authentication configuration
The application requires `JWT_SECRET` in production. In Render, add a long random secret (at least 32 characters) under **Environment → Environment Variables**, save it, and redeploy. If it is missing, the login API now returns a clear configuration message instead of the generic "Internal server error".

## Password reset

The sign-in page includes **Forgot Password?**. Password reset requests use a single-use, hashed token that expires after the configured period.

For production email delivery on Render, configure:
- `RESEND_API_KEY` = your Resend API key
- `EMAIL_FROM` = a verified sender/domain in Resend
- `APP_URL` = the public URL users should return to (for example your Render URL or custom domain)

The database migration automatically creates the `password_reset_tokens` table on startup. Reset tokens are never stored in plaintext. If Resend is not configured, the API deliberately does not expose reset tokens; configure the email provider before relying on password recovery in production.


## Admin password recovery

The login page includes **Admin Password Recovery**. It sends a single-use, 1-hour reset link only when the submitted email matches `ADMIN_EMAIL` and belongs to an admin account. Configure `ADMIN_EMAIL`, `RESEND_API_KEY`, and `EMAIL_FROM` in Render. Password resets require at least 12 characters. For this deployment, the administrator password is intentionally the same as `ADMIN_EMAIL`; this is convenient but significantly weaker than using a unique password.


## New global trade, energy and logistics modules

This version adds:
- Multilingual UI switcher: English, Spanish, French, Portuguese, Arabic and Chinese.
- Oil & Energy Market with oil/refined-product supplier listings, indicative price board and company profiles.
- Company-to-company and country-to-country trade structure through supplier listings, quotes, destination fields and global shipping workflows.
- Manual admin shipment tracker with tracking code, carrier, origin/destination, progress %, customer-facing notes, timeline events, ETA and calculated days remaining.
- Oil-company shareholder-interest workflow. It records a user's requested share quantity for admin/compliance review. It intentionally does **not** transfer money, custody securities, execute trades or represent a regulated brokerage service.
- Admin-adjustable oil price board. Prices are marked as admin-managed/indicative unless a trusted market-data provider is connected.
- Chatway widget integration through `CHATWAY_WIDGET_ID`.

### Chatway setup

Chatway requires the site owner to create the Chatway account and widget, then copy the widget ID into Render:

`CHATWAY_WIDGET_ID=your_widget_id`

The website loads Chatway automatically when this variable contains a real widget ID. Chatway's official installation guide says to sign up, create the widget, copy its installation code/ID, and add it to the site. See the official guide: https://chatway.app/help/how-to-install-chatway/how-to-install-chatway-on-any-website

Do not commit Chatway credentials or other secrets to GitHub.

### Regulated finance and oil trading

The oil supplier marketplace is a B2B/B2C trade workflow. The price board is not a promise of live market data. The shareholder-interest module is a request/record workflow, not a securities exchange or broker. Before enabling real securities purchases, share custody, investor funds, or regulated oil/commodity trading, connect licensed/regulated providers and implement KYC/AML, investor disclosures, suitability/eligibility, sanctions screening, settlement, tax and country-specific licensing requirements.
