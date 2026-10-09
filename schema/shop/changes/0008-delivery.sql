--liquibase formatted sql

--changeset lab:0008-shipments
CREATE TABLE shop.shipments (
    id               bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_id         bigint NOT NULL REFERENCES shop.orders (id),
    warehouse_id     smallint NOT NULL REFERENCES shop.warehouses (id),
    carrier_id       smallint NOT NULL REFERENCES shop.carriers (id),
    tracking_number  text NOT NULL,
    status           text NOT NULL CHECK (status IN ('preparing', 'in_transit', 'delivered', 'returned')),
    shipped_at       timestamptz,
    delivered_at     timestamptz
);
CREATE INDEX shipments_order_id_idx ON shop.shipments (order_id);
CREATE INDEX shipments_warehouse_id_idx ON shop.shipments (warehouse_id);
CREATE INDEX shipments_carrier_id_idx ON shop.shipments (carrier_id);
--rollback DROP TABLE shop.shipments;

--changeset lab:0008-shipment-events
--comment: BIG, append-only and time-ordered: a BRIN index fits created_at. EXERCISE 5 (see README): no primary key.
CREATE TABLE shop.shipment_events (
    shipment_id  bigint NOT NULL REFERENCES shop.shipments (id),
    event        text NOT NULL,
    location     text,
    created_at   timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX shipment_events_shipment_id_idx ON shop.shipment_events (shipment_id);
CREATE INDEX shipment_events_created_at_brin ON shop.shipment_events USING brin (created_at);
--rollback DROP TABLE shop.shipment_events;
