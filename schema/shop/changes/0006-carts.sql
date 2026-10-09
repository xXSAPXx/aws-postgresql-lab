--liquibase formatted sql

--changeset lab:0006-carts
--comment: HOT: constant inserts, updates and deletes (a bloat generator). customer_id is NULL for guests.
CREATE TABLE shop.carts (
    id           bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_id  integer REFERENCES shop.customers (id),
    status       text NOT NULL DEFAULT 'open' CHECK (status IN ('open', 'converted', 'abandoned')),
    created_at   timestamptz NOT NULL DEFAULT now(),
    updated_at   timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX carts_customer_id_idx ON shop.carts (customer_id);
CREATE INDEX carts_open_updated_at_idx ON shop.carts (updated_at) WHERE status = 'open';
--rollback DROP TABLE shop.carts;

--changeset lab:0006-cart-items
CREATE TABLE shop.cart_items (
    cart_id     bigint NOT NULL REFERENCES shop.carts (id) ON DELETE CASCADE,
    product_id  bigint NOT NULL REFERENCES shop.products (id),
    quantity    integer NOT NULL CHECK (quantity > 0),
    added_at    timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (cart_id, product_id)
);
CREATE INDEX cart_items_product_id_idx ON shop.cart_items (product_id);
--rollback DROP TABLE shop.cart_items;
