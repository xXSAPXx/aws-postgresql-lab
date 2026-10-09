--liquibase formatted sql

--changeset lab:1005-data-coupons context:data
INSERT INTO shop.coupons (code, discount_percent, valid_from, valid_to, max_uses)
SELECT 'SAVE' || lpad(g::text, 4, '0'),
       (ARRAY[5, 10, 15, 20, 25])[1 + g % 5],
       now() - interval '1 year' + (g % 12) * interval '1 month',
       now() - interval '1 year' + (g % 12 + 2) * interval '1 month',
       CASE WHEN g % 4 = 0 THEN 1000 END
FROM generate_series(1, 500) g;
--rollback DELETE FROM shop.coupons;

--changeset lab:1005-data-orders context:data
--comment: 600,000 orders per scale unit over the last year, more of them recently; inserted in time order, so ids grow with created_at. Older orders are delivered, recent ones still pending, paid or shipped.
INSERT INTO shop.orders (customer_id, shipping_address_id, status, currency, created_at, updated_at)
SELECT o.customer_id,
       (SELECT a.id FROM shop.customer_addresses a
         WHERE a.customer_id = o.customer_id AND a.kind = 'shipping' ORDER BY a.id LIMIT 1),
       o.status,
       'EUR',
       now() - o.age,
       now() - o.age + CASE o.status WHEN 'pending' THEN interval '0' WHEN 'paid' THEN interval '10 minutes'
                                     WHEN 'shipped' THEN interval '1 day' ELSE interval '4 days' END
FROM (
    SELECT cu.lo + floor(power(random(), 1.5) * cu.n)::int AS customer_id,
           a.age,
           CASE WHEN a.age < interval '1 day' THEN (ARRAY['pending', 'paid'])[1 + floor(random() * 2)::int]
                WHEN a.age < interval '5 days' THEN (ARRAY['paid', 'shipped', 'shipped'])[1 + floor(random() * 3)::int]
                WHEN random() < 0.03 THEN 'cancelled'
                WHEN random() < 0.02 THEN 'refunded'
                ELSE 'delivered' END AS status
    FROM generate_series(1, 600000 * ${shop_scale}) g
    CROSS JOIN (SELECT min(id) AS lo, count(*) AS n FROM shop.customers) cu
    CROSS JOIN LATERAL (SELECT power(random(), 1.3) * interval '365 days' + 0 * g * interval '1 second' AS age) a
) o
ORDER BY now() - o.age;
--rollback DELETE FROM shop.orders;

--changeset lab:1005-data-order-items context:data
--comment: 1-4 lines per order. Product popularity is skewed: about 21% of all lines are for the top 1% of products.
INSERT INTO shop.order_items (order_id, product_id, quantity, unit_price)
SELECT o.id, p.id, 1 + floor(power(random(), 3) * 4)::int, p.price
FROM shop.orders o
CROSS JOIN (SELECT min(id) AS lo, count(*) AS n FROM shop.products) b
CROSS JOIN LATERAL generate_series(1, 1 + floor(random() * 4)::int + 0 * o.id::int) item
CROSS JOIN LATERAL (SELECT b.lo + floor(power(random(), 3) * b.n)::bigint + 0 * item + 0 * o.id AS product_id) pick
JOIN shop.products p ON p.id = pick.product_id
ORDER BY o.id;
--rollback DELETE FROM shop.order_items;

--changeset lab:1005-data-order-totals context:data
UPDATE shop.orders o
SET total_amount = t.total
FROM (SELECT order_id, sum(quantity * unit_price) AS total FROM shop.order_items GROUP BY order_id) t
WHERE t.order_id = o.id;
--rollback UPDATE shop.orders SET total_amount = 0;

--changeset lab:1005-data-order-status-history context:data
INSERT INTO shop.order_status_history (order_id, from_status, to_status, changed_at)
SELECT o.id, s.from_status, s.to_status, o.created_at + s.step * (o.updated_at - o.created_at) / 3
FROM shop.orders o
CROSS JOIN (VALUES (0, NULL, 'pending'), (1, 'pending', 'paid'), (2, 'paid', 'shipped'), (3, 'shipped', 'delivered')) s(step, from_status, to_status)
WHERE s.step <= CASE o.status WHEN 'pending' THEN 0 WHEN 'paid' THEN 1 WHEN 'shipped' THEN 2
                              WHEN 'delivered' THEN 3 WHEN 'refunded' THEN 3 ELSE 0 END
ORDER BY o.id, s.step;
INSERT INTO shop.order_status_history (order_id, from_status, to_status, changed_at)
SELECT o.id, CASE o.status WHEN 'cancelled' THEN 'pending' ELSE 'delivered' END, o.status, o.updated_at
FROM shop.orders o
WHERE o.status IN ('cancelled', 'refunded')
ORDER BY o.id;
--rollback DELETE FROM shop.order_status_history;

--changeset lab:1005-data-payments context:data
INSERT INTO shop.payments (order_id, amount, method, status, provider_ref, created_at, updated_at)
SELECT o.id, o.total_amount,
       (ARRAY['card', 'card', 'card', 'paypal', 'bank_transfer', 'gift_card'])[1 + (o.id % 6)::int],
       CASE o.status WHEN 'pending' THEN 'pending' WHEN 'cancelled' THEN 'failed' WHEN 'refunded' THEN 'refunded' ELSE 'captured' END,
       'PSP-' || substr(md5(o.id::text), 1, 16),
       o.created_at, o.updated_at
FROM shop.orders o
ORDER BY o.id;
--rollback DELETE FROM shop.payments;

--changeset lab:1005-data-refunds-invoices-coupons context:data
INSERT INTO shop.refunds (payment_id, amount, reason, created_at)
SELECT p.id, p.amount, (ARRAY['damaged', 'wrong item', 'changed mind', 'late delivery'])[1 + (p.id % 4)::int], p.updated_at
FROM shop.payments p
WHERE p.status = 'refunded' AND p.amount > 0;
INSERT INTO shop.invoices (order_id, number, issued_at)
SELECT o.id, 'INV-' || to_char(o.created_at, 'YYYY') || '-' || lpad(o.id::text, 9, '0'), o.created_at + interval '5 minutes'
FROM shop.orders o
WHERE o.status IN ('paid', 'shipped', 'delivered', 'refunded')
ORDER BY o.id;
INSERT INTO shop.order_coupons (order_id, coupon_id)
SELECT o.id, cp.lo + (o.id % cp.n)::int
FROM shop.orders o
CROSS JOIN (SELECT min(id) AS lo, count(*) AS n FROM shop.coupons) cp
WHERE o.id % 10 = 0;
UPDATE shop.coupons c
SET used_count = u.n
FROM (SELECT coupon_id, count(*) AS n FROM shop.order_coupons GROUP BY coupon_id) u
WHERE u.coupon_id = c.id;
--rollback DELETE FROM shop.order_coupons;
--rollback DELETE FROM shop.invoices;
--rollback DELETE FROM shop.refunds;

--changeset lab:1005-data-shipments context:data
INSERT INTO shop.shipments (order_id, warehouse_id, carrier_id, tracking_number, status, shipped_at, delivered_at)
SELECT o.id,
       (w.lo + o.id % w.n)::smallint,
       (c.lo + o.id % c.n)::smallint,
       'TRK' || lpad(o.id::text, 12, '0'),
       CASE o.status WHEN 'shipped' THEN 'in_transit' WHEN 'refunded' THEN 'returned' ELSE 'delivered' END,
       o.created_at + interval '1 day',
       CASE WHEN o.status IN ('delivered', 'refunded') THEN o.created_at + interval '3 days' END
FROM shop.orders o
CROSS JOIN (SELECT min(id) AS lo, count(*) AS n FROM shop.warehouses) w
CROSS JOIN (SELECT min(id) AS lo, count(*) AS n FROM shop.carriers) c
WHERE o.status IN ('shipped', 'delivered', 'refunded')
ORDER BY o.id;
--rollback DELETE FROM shop.shipments;

--changeset lab:1005-data-shipment-events context:data
--comment: Inserted in time order, like a real event log: that is what makes the BRIN index on created_at effective.
INSERT INTO shop.shipment_events (shipment_id, event, location, created_at)
SELECT s.id, e.event, e.location, s.shipped_at + e.offset_time
FROM shop.shipments s
CROSS JOIN (VALUES ('label_created', 'warehouse', interval '-12 hours'), ('picked_up', 'warehouse', interval '0'),
                   ('in_transit', 'hub', interval '1 day'), ('delivered', 'customer', interval '2 days')) e(event, location, offset_time)
WHERE e.event <> 'delivered' OR s.status IN ('delivered', 'returned')
ORDER BY s.shipped_at + e.offset_time;
--rollback DELETE FROM shop.shipment_events;

--changeset lab:1005-data-stock-sales context:data
INSERT INTO shop.stock_movements (warehouse_id, product_id, quantity, reason, order_id, created_at)
SELECT (w.lo + oi.order_id % w.n)::smallint, oi.product_id, -oi.quantity, 'sale', oi.order_id, o.created_at
FROM shop.order_items oi
JOIN shop.orders o ON o.id = oi.order_id
CROSS JOIN (SELECT min(id) AS lo, count(*) AS n FROM shop.warehouses) w
WHERE o.status <> 'cancelled'
ORDER BY o.created_at;
--rollback DELETE FROM shop.stock_movements WHERE reason = 'sale';

--changeset lab:1005-data-audit-log context:data
--comment: 500,000 audit rows per scale unit over the last 360 days, routed to the monthly partitions.
INSERT INTO shop.audit_log (occurred_at, actor, action, entity, entity_id, details)
SELECT t.at,
       'customer:' || (cu.lo + floor(random() * cu.n)::int),
       (ARRAY['login', 'logout', 'view', 'update', 'checkout'])[1 + floor(random() * 5)::int],
       (ARRAY['customer', 'order', 'cart', 'product'])[1 + floor(random() * 4)::int],
       floor(random() * 1000000)::bigint,
       jsonb_build_object('ip', '10.' || floor(random() * 255)::int || '.' || floor(random() * 255)::int || '.1',
                          'user_agent', 'labapp')
FROM generate_series(1, 500000 * ${shop_scale}) g
CROSS JOIN (SELECT min(id) AS lo, count(*) AS n FROM shop.customers) cu
CROSS JOIN LATERAL (SELECT now() - random() * interval '360 days' + 0 * g * interval '1 second' AS at) t
ORDER BY t.at;
--rollback DELETE FROM shop.audit_log;

--changeset lab:1099-data-vacuum-analyze context:data runInTransaction:false
--comment: Fresh statistics for the planner and visibility maps for index-only scans after the bulk load.
VACUUM (ANALYZE) shop.countries, shop.carriers, shop.warehouses, shop.categories, shop.brands, shop.suppliers,
    shop.products, shop.product_prices, shop.product_attributes, shop.customers, shop.customer_addresses,
    shop.wishlists, shop.product_reviews, shop.inventory, shop.stock_movements, shop.carts, shop.cart_items,
    shop.coupons, shop.orders, shop.order_items, shop.order_coupons, shop.order_status_history, shop.payments,
    shop.refunds, shop.invoices, shop.shipments, shop.shipment_events, shop.audit_log;
--rollback SELECT 1;
