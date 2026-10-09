--liquibase formatted sql

--changeset lab:1004-data-inventory context:data
--comment: Every product in every warehouse; about 2% out of stock.
INSERT INTO shop.inventory (warehouse_id, product_id, quantity, reserved, updated_at)
SELECT w.id, p.id,
       CASE WHEN random() < 0.02 THEN 0 ELSE 50 + floor(random() * 950)::int END,
       0,
       now() - random() * interval '30 days'
FROM shop.warehouses w
CROSS JOIN shop.products p
ORDER BY w.id, p.id;
--rollback DELETE FROM shop.inventory;

--changeset lab:1004-data-stock-purchases context:data
--comment: The initial stock arrives as purchases in the ledger.
INSERT INTO shop.stock_movements (warehouse_id, product_id, quantity, reason, created_at)
SELECT i.warehouse_id, i.product_id, i.quantity + 100, 'purchase', now() - interval '13 months' + random() * interval '30 days'
FROM shop.inventory i;
--rollback DELETE FROM shop.stock_movements WHERE reason = 'purchase';

--changeset lab:1004-data-carts context:data
--comment: 50,000 carts per scale unit: 20% guests, most abandoned or still open.
INSERT INTO shop.carts (customer_id, status, created_at, updated_at)
SELECT CASE WHEN random() < 0.8 THEN cu.lo + floor(random() * cu.n)::int END,
       (ARRAY['open', 'open', 'abandoned', 'abandoned', 'abandoned', 'converted'])[1 + floor(random() * 6)::int],
       t.created,
       t.created + random() * interval '2 hours'
FROM generate_series(1, 50000 * ${shop_scale}) g
CROSS JOIN (SELECT min(id) AS lo, count(*) AS n FROM shop.customers) cu
CROSS JOIN LATERAL (SELECT now() - random() * interval '60 days' + 0 * g * interval '1 second' AS created) t
ORDER BY t.created;
--rollback DELETE FROM shop.carts;

--changeset lab:1004-data-cart-items context:data
INSERT INTO shop.cart_items (cart_id, product_id, quantity, added_at)
SELECT c.id,
       pr.lo + floor(power(random(), 2) * pr.n)::bigint,
       1 + floor(random() * 3)::int,
       c.created_at
FROM shop.carts c
CROSS JOIN (SELECT min(id) AS lo, count(*) AS n FROM shop.products) pr
CROSS JOIN LATERAL generate_series(1, 1 + floor(random() * 4)::int + 0 * c.id::int) item
ON CONFLICT DO NOTHING;
--rollback DELETE FROM shop.cart_items;
