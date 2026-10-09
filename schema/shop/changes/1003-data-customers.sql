--liquibase formatted sql

--changeset lab:1003-data-customers context:data
--comment: 200,000 customers per scale unit. Ids start at 2,140,000,000 (EXERCISE 1), so keep shop_scale below 30.
INSERT INTO shop.customers (email, first_name, last_name, country_code, status, marketing_opt_in, created_at, last_seen_at)
SELECT 'customer' || g || '@example.com',
       (ARRAY['Anna', 'Ben', 'Clara', 'David', 'Elena', 'Felix', 'Greta', 'Hugo', 'Ivana', 'Jonas',
              'Katya', 'Leo', 'Maria', 'Nikola', 'Olga', 'Peter', 'Rosa', 'Simeon', 'Tara', 'Viktor'])[1 + g % 20],
       (ARRAY['Petrov', 'Schmidt', 'Garcia', 'Rossi', 'Novak', 'Jansen', 'Dubois', 'Kowalski', 'Silva', 'Larsen',
              'Ivanova', 'Murphy', 'Horvat', 'Nagy', 'Popescu', 'Smith', 'Berg', 'Costa', 'Weber', 'Moreau'])[1 + (g / 20) % 20],
       cc.codes[1 + g % array_length(cc.codes, 1)],
       CASE WHEN g % 97 = 0 THEN 'closed' WHEN g % 53 = 0 THEN 'suspended' ELSE 'active' END,
       g % 3 = 0,
       t.created,
       t.created + random() * (now() - t.created)
FROM generate_series(1, 200000 * ${shop_scale}) g
CROSS JOIN (SELECT array_agg(code ORDER BY code) AS codes FROM shop.countries) cc
CROSS JOIN LATERAL (SELECT now() - random() * interval '3 years' + 0 * g * interval '1 second' AS created) t;
--rollback DELETE FROM shop.customers;

--changeset lab:1003-data-customer-addresses context:data
--comment: Every customer has a default shipping address; every second one also a billing address.
INSERT INTO shop.customer_addresses (customer_id, kind, line1, city, postal_code, country_code, is_default)
SELECT c.id, 'shipping',
       (1 + c.id % 250) || ' ' || (ARRAY['Main Street', 'Station Road', 'Park Avenue', 'Church Lane', 'Market Square', 'River Road'])[1 + c.id % 6],
       (ARRAY['Sofia', 'Berlin', 'Madrid', 'Paris', 'Rome', 'Vienna', 'Warsaw', 'Lisbon', 'Dublin', 'Prague'])[1 + c.id % 10],
       lpad((c.id % 99999)::text, 5, '0'), c.country_code, true
FROM shop.customers c
ORDER BY c.id;
INSERT INTO shop.customer_addresses (customer_id, kind, line1, city, postal_code, country_code, is_default)
SELECT c.id, 'billing',
       (1 + c.id % 120) || ' Office Park',
       (ARRAY['Sofia', 'Berlin', 'Madrid', 'Paris', 'Rome', 'Vienna', 'Warsaw', 'Lisbon', 'Dublin', 'Prague'])[1 + c.id % 10],
       lpad((c.id % 99999)::text, 5, '0'), c.country_code, false
FROM shop.customers c
WHERE c.id % 2 = 0
ORDER BY c.id;
--rollback DELETE FROM shop.customer_addresses;

--changeset lab:1003-data-wishlists context:data
INSERT INTO shop.wishlists (customer_id, product_id, added_at)
SELECT cu.lo + floor(random() * cu.n)::int,
       pr.lo + floor(power(random(), 2) * pr.n)::bigint,
       now() - random() * interval '1 year'
FROM generate_series(1, 150000 * ${shop_scale}) g
CROSS JOIN (SELECT min(id) AS lo, count(*) AS n FROM shop.customers) cu
CROSS JOIN (SELECT min(id) AS lo, count(*) AS n FROM shop.products) pr
ON CONFLICT DO NOTHING;
--rollback DELETE FROM shop.wishlists;

--changeset lab:1003-data-product-reviews context:data
INSERT INTO shop.product_reviews (product_id, customer_id, rating, title, body, created_at)
SELECT pr.lo + floor(power(random(), 2) * pr.n)::bigint,
       cu.lo + floor(random() * cu.n)::int,
       (ARRAY[1, 2, 3, 4, 4, 5, 5, 5])[1 + floor(random() * 8)::int],
       (ARRAY['Great', 'Good value', 'Not bad', 'Disappointing', 'Excellent', 'As described', 'Would buy again', 'Broke quickly'])[1 + floor(random() * 8)::int],
       'Generated review.',
       now() - random() * interval '2 years'
FROM generate_series(1, 100000 * ${shop_scale}) g
CROSS JOIN (SELECT min(id) AS lo, count(*) AS n FROM shop.customers) cu
CROSS JOIN (SELECT min(id) AS lo, count(*) AS n FROM shop.products) pr;
--rollback DELETE FROM shop.product_reviews;
