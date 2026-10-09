--liquibase formatted sql

--changeset lab:0010-analytics-and-batch-access
--comment: Two more application roles (created by Ansible, like every login): shop_analytics for long-running read-only reports and exports, shop_batch for the scheduled batch jobs.
GRANT CONNECT ON DATABASE shop TO shop_analytics, shop_batch;
GRANT USAGE ON SCHEMA shop TO shop_analytics, shop_batch;
GRANT SELECT ON ALL TABLES IN SCHEMA shop TO shop_analytics, shop_batch;
ALTER DEFAULT PRIVILEGES IN SCHEMA shop GRANT SELECT ON TABLES TO shop_analytics, shop_batch;
GRANT UPDATE ON shop.inventory, shop.carts TO shop_batch;
GRANT DELETE ON shop.carts, shop.cart_items TO shop_batch;
GRANT INSERT ON shop.stock_movements TO shop_batch;
--rollback REVOKE INSERT ON shop.stock_movements FROM shop_batch;
--rollback REVOKE DELETE ON shop.carts, shop.cart_items FROM shop_batch;
--rollback REVOKE UPDATE ON shop.inventory, shop.carts FROM shop_batch;
--rollback ALTER DEFAULT PRIVILEGES IN SCHEMA shop REVOKE SELECT ON TABLES FROM shop_analytics, shop_batch;
--rollback REVOKE SELECT ON ALL TABLES IN SCHEMA shop FROM shop_analytics, shop_batch;
--rollback REVOKE USAGE ON SCHEMA shop FROM shop_analytics, shop_batch;
--rollback REVOKE CONNECT ON DATABASE shop FROM shop_analytics, shop_batch;
