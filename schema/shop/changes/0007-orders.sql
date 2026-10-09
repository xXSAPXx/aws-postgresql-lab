--liquibase formatted sql

--changeset lab:0007-coupons
CREATE TABLE shop.coupons (
    id                integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    code              text NOT NULL UNIQUE,
    discount_percent  numeric(5,2) NOT NULL CHECK (discount_percent > 0 AND discount_percent <= 100),
    valid_from        timestamptz NOT NULL,
    valid_to          timestamptz NOT NULL,
    max_uses          integer CHECK (max_uses > 0),
    used_count        integer NOT NULL DEFAULT 0 CHECK (used_count >= 0)
);
--rollback DROP TABLE shop.coupons;

--changeset lab:0007-orders
--comment: HOT and BIG. EXERCISE 3 (see README): the biggest, fastest-growing table is not partitioned.
CREATE TABLE shop.orders (
    id                   bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_id          integer NOT NULL REFERENCES shop.customers (id),
    shipping_address_id  bigint REFERENCES shop.customer_addresses (id),
    status               text NOT NULL CHECK (status IN ('pending', 'paid', 'shipped', 'delivered', 'cancelled', 'refunded')),
    total_amount         numeric(12,2) NOT NULL DEFAULT 0 CHECK (total_amount >= 0),
    currency             char(3) NOT NULL DEFAULT 'EUR',
    created_at           timestamptz NOT NULL DEFAULT now(),
    updated_at           timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX orders_customer_id_created_at_idx ON shop.orders (customer_id, created_at DESC);
CREATE INDEX orders_created_at_idx ON shop.orders (created_at);
CREATE INDEX orders_shipping_address_id_idx ON shop.orders (shipping_address_id);
CREATE INDEX orders_open_status_idx ON shop.orders (status, created_at) WHERE status IN ('pending', 'paid');
--rollback DROP TABLE shop.orders;

--changeset lab:0007-order-items
--comment: BIG: the largest table. EXERCISE 2 (see README): the foreign key to products has no index.
CREATE TABLE shop.order_items (
    id          bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_id    bigint NOT NULL REFERENCES shop.orders (id),
    product_id  bigint NOT NULL REFERENCES shop.products (id),
    quantity    integer NOT NULL CHECK (quantity > 0),
    unit_price  numeric(10,2) NOT NULL CHECK (unit_price >= 0)
);
CREATE INDEX order_items_order_id_idx ON shop.order_items (order_id);
--rollback DROP TABLE shop.order_items;

--changeset lab:0007-order-coupons
CREATE TABLE shop.order_coupons (
    order_id   bigint NOT NULL REFERENCES shop.orders (id),
    coupon_id  integer NOT NULL REFERENCES shop.coupons (id),
    PRIMARY KEY (order_id, coupon_id)
);
CREATE INDEX order_coupons_coupon_id_idx ON shop.order_coupons (coupon_id);
--rollback DROP TABLE shop.order_coupons;

--changeset lab:0007-order-status-history
--comment: Append-only: one row per status change.
CREATE TABLE shop.order_status_history (
    id           bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_id     bigint NOT NULL REFERENCES shop.orders (id),
    from_status  text,
    to_status    text NOT NULL,
    changed_at   timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX order_status_history_order_id_idx ON shop.order_status_history (order_id);
--rollback DROP TABLE shop.order_status_history;

--changeset lab:0007-payments
--comment: HOT: status updates as payments are captured.
CREATE TABLE shop.payments (
    id            bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_id      bigint NOT NULL REFERENCES shop.orders (id),
    amount        numeric(12,2) NOT NULL CHECK (amount >= 0),
    method        text NOT NULL CHECK (method IN ('card', 'paypal', 'bank_transfer', 'gift_card')),
    status        text NOT NULL CHECK (status IN ('pending', 'captured', 'failed', 'refunded')),
    provider_ref  text,
    created_at    timestamptz NOT NULL DEFAULT now(),
    updated_at    timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX payments_order_id_idx ON shop.payments (order_id);
CREATE INDEX payments_pending_created_at_idx ON shop.payments (created_at) WHERE status = 'pending';
--rollback DROP TABLE shop.payments;

--changeset lab:0007-refunds
CREATE TABLE shop.refunds (
    id          bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    payment_id  bigint NOT NULL REFERENCES shop.payments (id),
    amount      numeric(12,2) NOT NULL CHECK (amount > 0),
    reason      text NOT NULL,
    created_at  timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX refunds_payment_id_idx ON shop.refunds (payment_id);
--rollback DROP TABLE shop.refunds;

--changeset lab:0007-invoices
CREATE TABLE shop.invoices (
    id         bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_id   bigint NOT NULL UNIQUE REFERENCES shop.orders (id),
    number     text NOT NULL UNIQUE,
    issued_at  timestamptz NOT NULL DEFAULT now()
);
--rollback DROP TABLE shop.invoices;

--changeset lab:0007-stock-movements-order-fk
--comment: Now that orders exists: stock movements of sales point to their order.
ALTER TABLE shop.stock_movements ADD CONSTRAINT stock_movements_order_id_fkey FOREIGN KEY (order_id) REFERENCES shop.orders (id);
CREATE INDEX stock_movements_order_id_idx ON shop.stock_movements (order_id);
--rollback DROP INDEX shop.stock_movements_order_id_idx;
--rollback ALTER TABLE shop.stock_movements DROP CONSTRAINT stock_movements_order_id_fkey;
