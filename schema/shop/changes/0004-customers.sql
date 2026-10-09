--liquibase formatted sql

--changeset lab:0004-customers
--comment: EXERCISE 1 (see README): id is an integer that starts near its limit (2,147,483,647). EXERCISE 4: customers_email_idx duplicates the unique constraint's index.
CREATE TABLE shop.customers (
    id                integer GENERATED ALWAYS AS IDENTITY (START WITH 2140000000) PRIMARY KEY,
    email             text NOT NULL,
    first_name        text NOT NULL,
    last_name         text NOT NULL,
    country_code      char(2) NOT NULL REFERENCES shop.countries (code),
    status            text NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'suspended', 'closed')),
    marketing_opt_in  boolean NOT NULL DEFAULT false,
    created_at        timestamptz NOT NULL DEFAULT now(),
    last_seen_at      timestamptz,
    CONSTRAINT customers_email_key UNIQUE (email)
);
CREATE INDEX customers_country_code_idx ON shop.customers (country_code);
CREATE INDEX customers_email_idx ON shop.customers (email);
--rollback DROP TABLE shop.customers;

--changeset lab:0004-customer-addresses
CREATE TABLE shop.customer_addresses (
    id            bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_id   integer NOT NULL REFERENCES shop.customers (id),
    kind          text NOT NULL CHECK (kind IN ('billing', 'shipping')),
    line1         text NOT NULL,
    city          text NOT NULL,
    postal_code   text NOT NULL,
    country_code  char(2) NOT NULL REFERENCES shop.countries (code),
    is_default    boolean NOT NULL DEFAULT false
);
CREATE INDEX customer_addresses_customer_id_idx ON shop.customer_addresses (customer_id);
CREATE INDEX customer_addresses_country_code_idx ON shop.customer_addresses (country_code);
--rollback DROP TABLE shop.customer_addresses;

--changeset lab:0004-wishlists
CREATE TABLE shop.wishlists (
    customer_id  integer NOT NULL REFERENCES shop.customers (id),
    product_id   bigint NOT NULL REFERENCES shop.products (id),
    added_at     timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (customer_id, product_id)
);
CREATE INDEX wishlists_product_id_idx ON shop.wishlists (product_id);
--rollback DROP TABLE shop.wishlists;

--changeset lab:0004-product-reviews
CREATE TABLE shop.product_reviews (
    id           bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    product_id   bigint NOT NULL REFERENCES shop.products (id),
    customer_id  integer NOT NULL REFERENCES shop.customers (id),
    rating       smallint NOT NULL CHECK (rating BETWEEN 1 AND 5),
    title        text NOT NULL,
    body         text,
    created_at   timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX product_reviews_product_id_created_at_idx ON shop.product_reviews (product_id, created_at DESC);
CREATE INDEX product_reviews_customer_id_idx ON shop.product_reviews (customer_id);
--rollback DROP TABLE shop.product_reviews;
