--liquibase formatted sql

--changeset lab:0002-countries
CREATE TABLE shop.countries (
    code    char(2) PRIMARY KEY,
    name    text NOT NULL UNIQUE,
    region  text NOT NULL
);
--rollback DROP TABLE shop.countries;

--changeset lab:0002-carriers
CREATE TABLE shop.carriers (
    id                     smallint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name                   text NOT NULL UNIQUE,
    tracking_url_template  text NOT NULL
);
--rollback DROP TABLE shop.carriers;

--changeset lab:0002-warehouses
CREATE TABLE shop.warehouses (
    id            smallint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    code          text NOT NULL UNIQUE,
    name          text NOT NULL,
    country_code  char(2) NOT NULL REFERENCES shop.countries (code)
);
CREATE INDEX warehouses_country_code_idx ON shop.warehouses (country_code);
--rollback DROP TABLE shop.warehouses;
