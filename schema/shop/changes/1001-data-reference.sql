--liquibase formatted sql

-- Data generation (context "data"). Sizes scale with the changelog parameter shop_scale (default 1).

--changeset lab:1001-data-countries context:data
INSERT INTO shop.countries (code, name, region) VALUES
    ('AT', 'Austria', 'Europe'), ('BE', 'Belgium', 'Europe'), ('BG', 'Bulgaria', 'Europe'), ('CH', 'Switzerland', 'Europe'),
    ('CZ', 'Czechia', 'Europe'), ('DE', 'Germany', 'Europe'), ('DK', 'Denmark', 'Europe'), ('ES', 'Spain', 'Europe'),
    ('FI', 'Finland', 'Europe'), ('FR', 'France', 'Europe'), ('GB', 'United Kingdom', 'Europe'), ('GR', 'Greece', 'Europe'),
    ('HR', 'Croatia', 'Europe'), ('HU', 'Hungary', 'Europe'), ('IE', 'Ireland', 'Europe'), ('IT', 'Italy', 'Europe'),
    ('NL', 'Netherlands', 'Europe'), ('NO', 'Norway', 'Europe'), ('PL', 'Poland', 'Europe'), ('PT', 'Portugal', 'Europe'),
    ('RO', 'Romania', 'Europe'), ('SE', 'Sweden', 'Europe'), ('SI', 'Slovenia', 'Europe'), ('SK', 'Slovakia', 'Europe'),
    ('US', 'United States', 'North America'), ('CA', 'Canada', 'North America'), ('MX', 'Mexico', 'North America'),
    ('BR', 'Brazil', 'South America'), ('JP', 'Japan', 'Asia'), ('AU', 'Australia', 'Oceania');
--rollback DELETE FROM shop.countries;

--changeset lab:1001-data-carriers context:data
INSERT INTO shop.carriers (name, tracking_url_template) VALUES
    ('DHL', 'https://track.example/dhl/%s'), ('UPS', 'https://track.example/ups/%s'),
    ('FedEx', 'https://track.example/fedex/%s'), ('DPD', 'https://track.example/dpd/%s'),
    ('GLS', 'https://track.example/gls/%s'), ('PostNL', 'https://track.example/postnl/%s');
--rollback DELETE FROM shop.carriers;

--changeset lab:1001-data-warehouses context:data
INSERT INTO shop.warehouses (code, name, country_code) VALUES
    ('BG-SOF', 'Sofia', 'BG'), ('DE-BER', 'Berlin', 'DE'), ('NL-AMS', 'Amsterdam', 'NL'),
    ('ES-MAD', 'Madrid', 'ES'), ('US-NJ', 'New Jersey', 'US');
--rollback DELETE FROM shop.warehouses;

--changeset lab:1001-data-categories context:data
INSERT INTO shop.categories (name, slug)
SELECT t.name, lower(t.name)
FROM unnest(ARRAY['Electronics', 'Computers', 'Home', 'Kitchen', 'Garden', 'Sports', 'Outdoors', 'Toys',
                  'Books', 'Music', 'Fashion', 'Shoes', 'Beauty', 'Health', 'Automotive']) WITH ORDINALITY t(name, n)
ORDER BY t.n;
INSERT INTO shop.categories (parent_id, name, slug)
SELECT p.id, p.name || ' ' || s.name, p.slug || '-' || lower(s.name)
FROM shop.categories p
CROSS JOIN unnest(ARRAY['Basics', 'Premium', 'Accessories', 'Essentials', 'Pro', 'Kids', 'Outlet', 'New']) s(name)
WHERE p.parent_id IS NULL
ORDER BY p.id, s.name;
--rollback DELETE FROM shop.categories;

--changeset lab:1001-data-brands context:data
INSERT INTO shop.brands (name)
SELECT 'Brand ' || lpad(g::text, 3, '0') FROM generate_series(1, 300) g;
--rollback DELETE FROM shop.brands;

--changeset lab:1001-data-suppliers context:data
INSERT INTO shop.suppliers (name, country_code, email)
SELECT 'Supplier ' || g, cc.codes[1 + g % array_length(cc.codes, 1)], 'orders@supplier' || g || '.example'
FROM generate_series(1, 100) g
CROSS JOIN (SELECT array_agg(code ORDER BY code) AS codes FROM shop.countries) cc;
--rollback DELETE FROM shop.suppliers;
