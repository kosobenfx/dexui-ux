CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE IF NOT EXISTS users(
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), name text NOT NULL, email text UNIQUE NOT NULL,
 password_hash text NOT NULL, role text NOT NULL DEFAULT 'buyer' CHECK(role IN('buyer','seller','admin')),
 status text NOT NULL DEFAULT 'active', email_verified boolean NOT NULL DEFAULT false, created_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE IF NOT EXISTS seller_applications(
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), user_id uuid REFERENCES users(id) ON DELETE CASCADE,
 business_name text NOT NULL, country text NOT NULL, business_email text NOT NULL, description text,
 status text NOT NULL DEFAULT 'pending' CHECK(status IN('pending','approved','rejected')), created_at timestamptz NOT NULL DEFAULT now(), reviewed_at timestamptz
);
CREATE TABLE IF NOT EXISTS sellers(
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), user_id uuid UNIQUE REFERENCES users(id) ON DELETE CASCADE,
 business_name text NOT NULL, country text NOT NULL, approved_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE IF NOT EXISTS seller_bank_accounts(
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), seller_id uuid UNIQUE REFERENCES sellers(id) ON DELETE CASCADE,
 bank_name text NOT NULL, account_name text NOT NULL, account_number text NOT NULL, routing_code text,
 swift_code text, iban text, currency char(3) NOT NULL DEFAULT 'USD', verified boolean NOT NULL DEFAULT false,
 created_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE IF NOT EXISTS products(
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), seller_id uuid REFERENCES sellers(id) ON DELETE CASCADE,
 name text NOT NULL, category text NOT NULL, description text NOT NULL, price numeric(14,2) NOT NULL,
 bulk_price numeric(14,2), moq integer NOT NULL DEFAULT 1, stock integer NOT NULL DEFAULT 0,
 currency char(3) NOT NULL DEFAULT 'USD', image_url text, active boolean NOT NULL DEFAULT true, created_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE IF NOT EXISTS orders(
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), buyer_id uuid REFERENCES users(id), currency char(3) NOT NULL DEFAULT 'USD',
 subtotal numeric(14,2) NOT NULL, protection_fee numeric(14,2) NOT NULL DEFAULT 0, total numeric(14,2) NOT NULL,
 status text NOT NULL DEFAULT 'pending_payment',
 payment_status text NOT NULL DEFAULT 'unpaid',
 payment_method text NOT NULL DEFAULT 'platform_escrow' CHECK(payment_method IN('platform_escrow','direct_wire')),
 escrow_status text NOT NULL DEFAULT 'not_funded',
 shipping_address jsonb NOT NULL DEFAULT '{}',
 delivery_confirmed_at timestamptz, inspection_confirmed_at timestamptz,
 dispute_deadline timestamptz, released_at timestamptz, created_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE IF NOT EXISTS order_items(
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), order_id uuid REFERENCES orders(id) ON DELETE CASCADE,
 product_id uuid REFERENCES products(id), seller_id uuid REFERENCES sellers(id), quantity integer NOT NULL CHECK(quantity>0), unit_price numeric(14,2) NOT NULL
);
CREATE TABLE IF NOT EXISTS payment_transactions(
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), order_id uuid UNIQUE REFERENCES orders(id) ON DELETE CASCADE,
 method text NOT NULL CHECK(method IN('platform_escrow','direct_wire')),
 status text NOT NULL DEFAULT 'awaiting_payment',
 reference text UNIQUE NOT NULL, amount numeric(14,2) NOT NULL, currency char(3) NOT NULL,
 payer_id uuid REFERENCES users(id), beneficiary_seller_id uuid REFERENCES sellers(id),
 bank_reference text, proof_url text, confirmed_by uuid REFERENCES users(id), confirmed_at timestamptz,
 created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE IF NOT EXISTS payment_ledger(
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), order_id uuid REFERENCES orders(id) ON DELETE CASCADE,
 seller_id uuid REFERENCES sellers(id), entry_type text NOT NULL CHECK(entry_type IN('buyer_funding','platform_fee','seller_release','refund','adjustment')),
 amount numeric(14,2) NOT NULL, currency char(3) NOT NULL, reference text NOT NULL, created_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE IF NOT EXISTS seller_releases(
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), order_id uuid REFERENCES orders(id) ON DELETE CASCADE,
 seller_id uuid REFERENCES sellers(id), amount numeric(14,2) NOT NULL, status text NOT NULL DEFAULT 'pending',
 bank_reference text, released_by uuid REFERENCES users(id), released_at timestamptz, UNIQUE(order_id,seller_id)
);
CREATE TABLE IF NOT EXISTS reviews(
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), product_id uuid REFERENCES products(id) ON DELETE CASCADE,
 buyer_id uuid REFERENCES users(id) ON DELETE CASCADE, order_id uuid REFERENCES orders(id) ON DELETE SET NULL,
 rating integer NOT NULL CHECK(rating BETWEEN 1 AND 5), body text NOT NULL, created_at timestamptz NOT NULL DEFAULT now(), UNIQUE(product_id,buyer_id,order_id)
);
CREATE TABLE IF NOT EXISTS quotes(
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), buyer_id uuid REFERENCES users(id), product_id uuid REFERENCES products(id),
 quantity integer NOT NULL, unit_price_target numeric(14,2), message text NOT NULL, status text NOT NULL DEFAULT 'pending', seller_message text, created_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE IF NOT EXISTS conversations(
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), buyer_id uuid REFERENCES users(id), seller_id uuid REFERENCES sellers(id), product_id uuid REFERENCES products(id),
 created_at timestamptz NOT NULL DEFAULT now(), UNIQUE(buyer_id,seller_id,product_id)
);
CREATE TABLE IF NOT EXISTS messages(
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), conversation_id uuid REFERENCES conversations(id) ON DELETE CASCADE,
 sender_id uuid REFERENCES users(id), body text NOT NULL, created_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE IF NOT EXISTS disputes(
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), order_id uuid REFERENCES orders(id), opened_by uuid REFERENCES users(id), reason text NOT NULL,
 description text NOT NULL, status text NOT NULL DEFAULT 'open', resolution text, created_at timestamptz NOT NULL DEFAULT now(), resolved_at timestamptz
);
CREATE TABLE IF NOT EXISTS dispute_messages(
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), dispute_id uuid REFERENCES disputes(id) ON DELETE CASCADE, sender_id uuid REFERENCES users(id), body text NOT NULL, created_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE IF NOT EXISTS broadcasts(
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), admin_id uuid REFERENCES users(id), audience text NOT NULL, subject text NOT NULL, body text NOT NULL,
 recipient_count integer NOT NULL DEFAULT 0, status text NOT NULL DEFAULT 'queued', created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_products_category ON products(category);
CREATE INDEX IF NOT EXISTS idx_messages_conversation ON messages(conversation_id,created_at);
CREATE INDEX IF NOT EXISTS idx_orders_buyer ON orders(buyer_id,created_at);
CREATE INDEX IF NOT EXISTS idx_orders_payment ON orders(payment_status,status);
CREATE INDEX IF NOT EXISTS idx_reviews_product ON reviews(product_id,created_at);
CREATE INDEX IF NOT EXISTS idx_payment_ledger_order ON payment_ledger(order_id,created_at);
