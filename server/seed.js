```js
require('dotenv').config();

const { query, pool } = require('./db');
const { hash } = require('./auth');

(async () => {
  try {
    const adminpassword = process.env.ADMIN_BOOTSTRAP_PASSWORD;

    if (!adminpassword || adminpassword.length < 12) {
      throw new Error(
        'Set ADMIN_BOOTSTRAP_PASSWORD (12+ chars) before running seed'
      );
    }

    let a = (
      await query(
        "SELECT id FROM users WHERE email='mambafxo6@gmail.com'"
      )
    ).rows[0];

    if (!a) {
      a = (
        await query(
          `INSERT INTO users
            (name, email, password_hash, role, email_verified)
           VALUES
            ($1, $2, $3, 'admin', true)
           RETURNING id`,
          [
            'Dexillionz Global Admin',
            'mambafxo6@gmail.com',
            await hash(adminpassword)
          ]
        )
      ).rows[0];
    } else {
      await query(
        `UPDATE users
         SET role='admin',
             email_verified=true,
             password_hash=$1
         WHERE id=$2`,
        [await hash(adminpassword), a.id]
      );
    }

    let s = (
      await query(
        'SELECT id FROM sellers WHERE user_id=$1',
        [a.id]
      )
    ).rows[0];

    if (!s) {
      s = (
        await query(
          `INSERT INTO sellers
            (user_id, business_name, country)
           VALUES
            ($1, 'Dexillionz Official Store', 'United States')
           RETURNING id`,
          [a.id]
        )
      ).rows[0];
    }

    const products = [
      [
        'BYD Shark 2026',
        'Vehicles',
        'New-energy pickup suitable for business and family use.',
        49800,
        47200,
        20,
        22
      ],
      [
        'Industrial Solar Panel 550W',
        'Energy',
        'High-output commercial solar panel.',
        119,
        92,
        20,
        1200
      ],
      [
        'Premium Arabica Coffee Beans',
        'Food',
        'Premium Arabica beans for wholesale and retail.',
        14.5,
        9.8,
        50,
        6500
      ],
      [
        'Smart LED Street Light',
        'Electronics',
        'Commercial smart LED street lighting.',
        74,
        58,
        20,
        830
      ],
      [
        'Construction Steel Rebar',
        'Construction',
        'Industrial construction-grade steel rebar.',
        680,
        625,
        100,
        430
      ],
      [
        '5G Rugged Smartphone',
        'Electronics',
        'Durable 5G smartphone for field operations.',
        289,
        245,
        20,
        390
      ],
      [
        'Organic Shea Butter 25kg',
        'Beauty',
        'Bulk organic shea butter.',
        165,
        132,
        20,
        2100
      ],
      [
        'Commercial Generator 15KVA',
        'Machinery',
        'Commercial generator for reliable backup power.',
        3400,
        3150,
        5,
        77
      ]
    ];

    for (const p of products) {
      await query(
        `INSERT INTO products
          (seller_id, name, category, description, price, bulk_price, moq, stock)
         SELECT $1, $2, $3, $4, $5, $6, $7, $8
         WHERE NOT EXISTS (
           SELECT 1 FROM products WHERE name=$2
         )`,
        [s.id, ...p]
      );
    }

    console.log(
      'Seeded admin: mambafxo6@gmail.com. Set a strong password through your deployment secret/admin provisioning flow before production use.'
    );
  } catch (e) {
    console.error(e);
    process.exitCode = 1;
  } finally {
    await pool.end();
  }
})();
```
