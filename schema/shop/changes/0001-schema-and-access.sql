--liquibase formatted sql

-- Migrations run as shop_migrator, which acts as shop_owner (ALTER ROLE shop_migrator SET role = shop_owner),
-- so every object below is owned by shop_owner. Nobody logs in as the owner.

--changeset lab:0001-schema
--comment: The shop schema, owned by shop_owner.
CREATE SCHEMA shop AUTHORIZATION shop_owner;
--rollback DROP SCHEMA shop;

--changeset lab:0001-search-path
--comment: Sessions in this database find the shop tables without the schema prefix.
ALTER DATABASE shop SET search_path TO shop, public;
--rollback ALTER DATABASE shop RESET search_path;

--changeset lab:0001-database-access
--comment: Only the shop roles and monitoring may connect to this database.
REVOKE CONNECT, TEMPORARY ON DATABASE shop FROM PUBLIC;
GRANT CONNECT ON DATABASE shop TO shop_app, shop_reporting, shop_migrator, pmm;
--rollback GRANT CONNECT, TEMPORARY ON DATABASE shop TO PUBLIC;

--changeset lab:0001-default-privileges
--comment: Tables and sequences created from now on get the right grants automatically.
GRANT USAGE ON SCHEMA shop TO shop_app, shop_reporting;
ALTER DEFAULT PRIVILEGES IN SCHEMA shop GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO shop_app;
ALTER DEFAULT PRIVILEGES IN SCHEMA shop GRANT USAGE, SELECT ON SEQUENCES TO shop_app;
ALTER DEFAULT PRIVILEGES IN SCHEMA shop GRANT SELECT ON TABLES TO shop_reporting;
--rollback ALTER DEFAULT PRIVILEGES IN SCHEMA shop REVOKE SELECT ON TABLES FROM shop_reporting;
--rollback ALTER DEFAULT PRIVILEGES IN SCHEMA shop REVOKE USAGE, SELECT ON SEQUENCES FROM shop_app;
--rollback ALTER DEFAULT PRIVILEGES IN SCHEMA shop REVOKE SELECT, INSERT, UPDATE, DELETE ON TABLES FROM shop_app;
--rollback REVOKE USAGE ON SCHEMA shop FROM shop_app, shop_reporting;
