--liquibase formatted sql

--changeset lab:0005-inventory
--comment: HOT: every order updates the stock rows of its products, and a few popular products get most orders.
CREATE TABLE shop.inventory (
    warehouse_id  smallint NOT NULL REFERENCES shop.warehouses (id),
    product_id    bigint NOT NULL REFERENCES shop.products (id),
    quantity      integer NOT NULL CHECK (quantity >= 0),
    reserved      integer NOT NULL DEFAULT 0 CHECK (reserved >= 0),
    updated_at    timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (warehouse_id, product_id)
);
CREATE INDEX inventory_product_id_idx ON shop.inventory (product_id);
--rollback DROP TABLE shop.inventory;

--changeset lab:0005-stock-movements
--comment: Append-only ledger of every stock change. The foreign key to orders is added with the orders table.
CREATE TABLE shop.stock_movements (
    id            bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    warehouse_id  smallint NOT NULL,
    product_id    bigint NOT NULL,
    quantity      integer NOT NULL CHECK (quantity <> 0),
    reason        text NOT NULL CHECK (reason IN ('purchase', 'sale', 'return', 'adjustment', 'transfer')),
    order_id      bigint,
    created_at    timestamptz NOT NULL DEFAULT now(),
    FOREIGN KEY (warehouse_id, product_id) REFERENCES shop.inventory (warehouse_id, product_id)
);
CREATE INDEX stock_movements_warehouse_id_product_id_idx ON shop.stock_movements (warehouse_id, product_id);
CREATE INDEX stock_movements_created_at_idx ON shop.stock_movements (created_at);
--rollback DROP TABLE shop.stock_movements;
