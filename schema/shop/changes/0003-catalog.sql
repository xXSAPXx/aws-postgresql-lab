--liquibase formatted sql

--changeset lab:0003-categories
--comment: A tree: top-level categories and their subcategories.
CREATE TABLE shop.categories (
    id         integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    parent_id  integer REFERENCES shop.categories (id),
    name       text NOT NULL,
    slug       text NOT NULL UNIQUE
);
CREATE INDEX categories_parent_id_idx ON shop.categories (parent_id);
--rollback DROP TABLE shop.categories;

--changeset lab:0003-brands
CREATE TABLE shop.brands (
    id    integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name  text NOT NULL UNIQUE
);
--rollback DROP TABLE shop.brands;

--changeset lab:0003-suppliers
CREATE TABLE shop.suppliers (
    id            integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name          text NOT NULL,
    country_code  char(2) NOT NULL REFERENCES shop.countries (code),
    email         text NOT NULL
);
CREATE INDEX suppliers_country_code_idx ON shop.suppliers (country_code);
--rollback DROP TABLE shop.suppliers;

--changeset lab:0003-products
CREATE TABLE shop.products (
    id            bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    sku           text NOT NULL UNIQUE,
    name          text NOT NULL,
    description   text,
    category_id   integer NOT NULL REFERENCES shop.categories (id),
    brand_id      integer NOT NULL REFERENCES shop.brands (id),
    supplier_id   integer NOT NULL REFERENCES shop.suppliers (id),
    price         numeric(10,2) NOT NULL CHECK (price > 0),
    weight_grams  integer NOT NULL CHECK (weight_grams > 0),
    active        boolean NOT NULL DEFAULT true,
    created_at    timestamptz NOT NULL DEFAULT now(),
    updated_at    timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX products_category_id_idx ON shop.products (category_id);
CREATE INDEX products_brand_id_idx ON shop.products (brand_id);
CREATE INDEX products_supplier_id_idx ON shop.products (supplier_id);
--rollback DROP TABLE shop.products;

--changeset lab:0003-product-prices
--comment: Price history: one row per price period.
CREATE TABLE shop.product_prices (
    id          bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    product_id  bigint NOT NULL REFERENCES shop.products (id),
    price       numeric(10,2) NOT NULL CHECK (price > 0),
    valid_from  timestamptz NOT NULL,
    valid_to    timestamptz,
    CHECK (valid_to IS NULL OR valid_to > valid_from)
);
CREATE INDEX product_prices_product_id_valid_from_idx ON shop.product_prices (product_id, valid_from);
--rollback DROP TABLE shop.product_prices;

--changeset lab:0003-product-attributes
CREATE TABLE shop.product_attributes (
    product_id  bigint NOT NULL REFERENCES shop.products (id) ON DELETE CASCADE,
    name        text NOT NULL,
    value       text NOT NULL,
    PRIMARY KEY (product_id, name)
);
--rollback DROP TABLE shop.product_attributes;
