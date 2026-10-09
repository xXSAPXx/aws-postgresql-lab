--liquibase formatted sql

--changeset lab:1002-data-products context:data
--comment: 20,000 products per scale unit.
INSERT INTO shop.products (sku, name, description, category_id, brand_id, supplier_id, price, weight_grams, active, created_at, updated_at)
SELECT 'SKU-' || lpad(g::text, 8, '0'),
       (ARRAY['Classic', 'Smart', 'Eco', 'Ultra', 'Mini', 'Pro', 'Max', 'Lite', 'Urban', 'Nordic'])[1 + g % 10] || ' '
           || (ARRAY['Lamp', 'Chair', 'Kettle', 'Backpack', 'Headphones', 'Jacket', 'Blender', 'Drill', 'Tent', 'Watch', 'Speaker', 'Mug'])[1 + (g / 10) % 12]
           || ' ' || g,
       'Generated product number ' || g || '.',
       c.ids[1 + g % array_length(c.ids, 1)],
       b.lo + (g * 7) % b.n,
       s.lo + g % s.n,
       round((4.99 + random() * 495)::numeric, 2),
       100 + floor(random() * 5000)::int,
       g % 50 <> 0,
       t.created,
       t.created + random() * (now() - t.created)
FROM generate_series(1, 20000 * ${shop_scale}) g
CROSS JOIN (SELECT array_agg(id ORDER BY id) AS ids FROM shop.categories WHERE parent_id IS NOT NULL) c
CROSS JOIN (SELECT min(id) AS lo, count(*)::int AS n FROM shop.brands) b
CROSS JOIN (SELECT min(id) AS lo, count(*)::int AS n FROM shop.suppliers) s
CROSS JOIN LATERAL (SELECT now() - random() * interval '3 years' + 0 * g * interval '1 second' AS created) t;
--rollback DELETE FROM shop.products;

--changeset lab:1002-data-product-prices context:data
--comment: Three price periods per product, the last one open-ended.
INSERT INTO shop.product_prices (product_id, price, valid_from, valid_to)
SELECT p.id,
       round(p.price * (0.8 + 0.1 * k), 2),
       now() - interval '1 year' + (k - 1) * interval '4 months',
       CASE WHEN k < 3 THEN now() - interval '1 year' + k * interval '4 months' END
FROM shop.products p
CROSS JOIN generate_series(1, 3) k
ORDER BY p.id, k;
--rollback DELETE FROM shop.product_prices;

--changeset lab:1002-data-product-attributes context:data
INSERT INTO shop.product_attributes (product_id, name, value)
SELECT p.id, a.name, a.name || '-' || (p.id % 7)
FROM shop.products p
CROSS JOIN (VALUES ('color'), ('size'), ('material'), ('warranty')) a(name);
--rollback DELETE FROM shop.product_attributes;
